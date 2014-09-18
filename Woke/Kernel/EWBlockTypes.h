//
//
//  Created by Zitao Xiong on 14/09/2014.
//


typedef void (^DictionaryBlock)(NSDictionary *dictionary);
typedef void (^BoolBlock)(BOOL success);
typedef void (^BoolErrorBlock)(BOOL success, NSError *error);
typedef void (^DictionaryErrorBlock)(NSDictionary *dictioanry, NSError *error);
typedef void (^ErrorBlock)(NSError *error);
typedef void (^VoidBlock)(void);
typedef void (^UIImageBlock)(UIImage *image);
typedef void (^ArrayBlock)(NSArray *array);
typedef void (^FloatBlock)(float percent);
typedef void (^SenderBlock)(id sender);
