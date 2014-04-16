@interface EWGroup : NSManagedObject {}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * ewgroup_id;
@property (nonatomic, retain) id imageKey;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * statement;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSDate * wakeupTime;
@property (nonatomic, retain) NSSet *admin;
@property (nonatomic, retain) NSSet *member;

@end


@interface EWGroup (CoreDataGeneratedAccessors)

- (void)addAdminObject:(EWPerson *)value;
- (void)removeAdminObject:(EWPerson *)value;
- (void)addAdmin:(NSSet *)values;
- (void)removeAdmin:(NSSet *)values;

- (void)addMemberObject:(EWPerson *)value;
- (void)removeMemberObject:(EWPerson *)value;
- (void)addMember:(NSSet *)values;
- (void)removeMember:(NSSet *)values;

@end
