#import <Foundation/Foundation.h>

@class RemotePostCategory;
@class RemotePostTag;
@class RemoteTaxonomyPaging;

/* Interface for requesting taxonomy such as tags and categories on a site.
 */
@protocol TaxonomyServiceRemote <NSObject>

/* Create a new category with the site.
 */
- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

/* Fetch a list of categories associated with the site.
 * Note: Requests no paging parameters via the API defaulting the response.
 */
- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *categories))success
                         failure:(void (^)(NSError *error))failure;

/* Fetch a list of categories associated with the site with paging.
 */
- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *categories))success
                          paging:(RemoteTaxonomyPaging *)paging
                         failure:(void (^)(NSError *error))failure;

/* Fetch a list of tags associated with the site.
 * Note: Requests no paging parameters via the API defaulting the response.
 */
- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure;

/* Fetch a list of tags associated with the site with paging.
 */
- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                    paging:(RemoteTaxonomyPaging *)paging
                   failure:(void (^)(NSError *error))failure;

@end