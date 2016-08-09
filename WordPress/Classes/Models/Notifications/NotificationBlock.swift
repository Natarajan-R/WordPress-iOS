import Foundation



// MARK: - NotificationBlock Implementation
//
class NotificationBlock: Equatable
{
    ///
    ///
    enum Kind {
        case Text
        case Image      // Includes Badges and Images
        case User
        case Comment
    }

    ///
    ///
    enum Action: String {
        case Approve    = "approve-comment"
        case Follow     = "follow"
        case Like       = "like-comment"
        case Reply      = "replyto-comment"
        case Spam       = "spam-comment"
        case Trash      = "trash-comment"
    }

    ///
    ///
    let actions: [String: AnyObject]?

    ///
    ///
    private var actionsOverride = [Action: Bool]()

    ///
    ///
    private var dynamicAttributesCache = [String: AnyObject]()

    ///
    ///
    let media: [NotificationMedia]

    ///
    ///
    let meta: [String: AnyObject]?

    ///
    ///
    private weak var parent: Notification?

    ///
    ///
    let ranges: [NotificationRange]

    ///
    ///
    private let type: String?

    ///
    ///
    let text: String?

    ///
    ///
    var textOverride: String? {
        didSet {
            parent?.didChangeOverrides()
        }
    }

    ///
    ///
    private typealias MetaKeys  = Notification.MetaKeys

    //
    ///
    private typealias BlockKeys = Notification.BlockKeys


    ///
    ///
    init(dictionary: [String: AnyObject], parent note: Notification) {
        let rawRanges = dictionary[BlockKeys.Ranges] as? [AnyObject]
        let parsedRanges = NotificationRange.rangesFromArray(rawRanges)

        let rawMedia = dictionary[BlockKeys.Media] as? [AnyObject]
        let parsedMedia = NotificationMedia.mediaFromArray(rawMedia)

        actions = dictionary[BlockKeys.Actions] as? [String: AnyObject]
        media   = parsedMedia
        meta    = dictionary[BlockKeys.Meta] as? [String: AnyObject]
        ranges  = parsedRanges
        parent  = note
        type    = dictionary[BlockKeys.RawType] as? String
        text    = dictionary[BlockKeys.Text] as? String
    }
}



// MARK: - NotificationBlock Computed Properties
//
extension NotificationBlock
{
    ///
    ///
    var kind: Kind {
        // Duck Typing code below: Infer block kind based on... stuff. (Sorry)
        //
        if let rawType = type where rawType.isEqual(BlockKeys.RawTypeUser) {
            return .User
        }

        if let commentID = metaCommentID, let parentCommentID = parent?.metaCommentID, let _ = metaSiteID
            where commentID.isEqual(parentCommentID)
        {
            return .Comment
        }

        if let firstMedia = media.first where firstMedia.isImage || firstMedia.isBadge {
            return .Image
        }

        return .Text
    }

    /// Returns all of the Image URL's referenced by the NotificationMedia instances
    ///
    var imageUrls: [NSURL] {
        return media.flatMap {
            guard $0.isImage && $0.mediaURL != nil else {
                return nil
            }

            return $0.mediaURL
        }
    }

    /// Returns YES if the associated comment (if any) is approved. NO otherwise.
    ///
    var isCommentApproved: Bool {
        return isActionOn(.Approve) || !isActionEnabled(.Approve)
    }

    /// Returns the Meta ID's collection, if any.
    ///
    private var metaIds: [String: AnyObject]? {
        return meta?[MetaKeys.Ids] as? [String: AnyObject]
    }

    /// Returns the Meta Links collection, if any.
    ///
    private var metaLinks: [String: AnyObject]? {
        return meta?[MetaKeys.Links] as? [String: AnyObject]
    }

    ///
    ///
    private var metaTitles: [String: AnyObject]? {
        return meta?[MetaKeys.Titles] as? [String: AnyObject]
    }

    ///
    ///
    var metaCommentID: NSNumber? {
        return metaIds?[MetaKeys.Comment] as? NSNumber
    }

    ///
    ///
    var metaLinksHome: NSURL? {
        guard let rawLink = metaLinks?[MetaKeys.Home] as? String else {
            return nil
        }

        return NSURL(string: rawLink)
    }

    ///
    ///
    var metaSiteID: NSNumber? {
        return metaIds?[MetaKeys.Site] as? NSNumber
    }

    ///
    ///
    var metaTitlesHome: String? {
        return metaTitles?[MetaKeys.Home] as? String
    }
}



// MARK: - NotificationBlock Methods
//
extension NotificationBlock
{
    /// Allows us to set a local override for a remote value. This is used to fake the UI, while
    /// there's a BG call going on.
    ///
    func setOverrideValue(value: Bool, forAction action: Action) {
        actionsOverride[action] = value
        parent?.didChangeOverrides()
    }

    /// Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
    ///
    func removeOverrideValueForAction(action: Action) {
        actionsOverride.removeValueForKey(action)
        parent?.didChangeOverrides()
    }

    /// Returns the Notification Block status for a given action. If there's any local override,
    /// the (override) value will be returned.
    ///
    private func valueForAction(action: Action) -> Bool? {
        guard let overrideValue = actionsOverride[action] else {
            let value = actions?[action.rawValue] as? NSNumber
            return value?.boolValue
        }

        return overrideValue
    }

    /// Returns *true* if a given action is available
    ///
    func isActionEnabled(action: Action) -> Bool {
        return valueForAction(action) != nil
    }

    /// Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
    /// is currently approved).
    ///
    func isActionOn(action: Action) -> Bool {
        return valueForAction(action) ?? false
    }

    // Dynamic Attribute Cache: used internally by the Interface Extension, as an optimization.
    ///
    func cacheValueForKey(key: String) -> AnyObject? {
        return self.dynamicAttributesCache[key]
    }

    ///
    ///
    func setCacheValue(value: AnyObject?, forKey key: String) {
        guard let value = value else {
            dynamicAttributesCache.removeValueForKey(key)
            return
        }

        dynamicAttributesCache[key] = value
    }

    /// Finds the first NotificationRange instance that maps to a given URL.
    ///
    func notificationRangeWithUrl(url: NSURL) -> NotificationRange? {
        for range in ranges {
            if let rangeURL = range.url where rangeURL.isEqual(url) {
                return range
            }
        }

        return nil
    }

    /// Finds the first NotificationRange instance that maps to a given CommentID.
    ///
    func notificationRangeWithCommentId(commentID: NSNumber) -> NotificationRange? {
        for range in ranges {
            if let rangeCommentID = range.commentID where rangeCommentID.isEqual(commentID) {
                return range
            }
        }

        return nil
    }

    ///
    ///
    class func firstBlockOfKind(kind: Kind, fromBlocksArray blocks: [NotificationBlock]) -> NotificationBlock? {
        for block in blocks where block.kind == kind {
            return block
        }

        return nil
    }
}



// MARK: - NotificationBlock Parsers
//
extension NotificationBlock
{
    ///
    ///
    class func blocksFromArray(rawBlocks: [AnyObject]?, parent: Notification) -> [NotificationBlock]? {
        guard let rawBlocks = rawBlocks where rawBlocks.isEmpty == false else {
            return nil
        }

        return rawBlocks.flatMap {
            guard let rawBlock = $0 as? [String: AnyObject] else {
                return nil
            }

            return NotificationBlock(dictionary: rawBlock, parent: parent)
        }
    }
}



// MARK: - NotificationBlock Equatable Implementation
//
func == (lhs: NotificationBlock, rhs: NotificationBlock) -> Bool {
    return lhs.kind == rhs.kind &&
        lhs.text == rhs.text &&
        lhs.parent == rhs.parent &&
        lhs.ranges.count == rhs.ranges.count &&
        lhs.media.count == rhs.media.count
}