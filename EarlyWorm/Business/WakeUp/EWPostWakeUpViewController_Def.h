//
//  EWPostWakeUpViewController_Def.h
//  EarlyWorm
//
//  Created by letv on 14-2-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#ifndef EarlyWorm_EWPostWakeUpViewController_Def_h
#define EarlyWorm_EWPostWakeUpViewController_Def_h

//Judge System

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)


//Collection View Identifier

#define COLLECTION_VIEW_IDENTIFIER  @"CollectionViewIdentifier"


//Collection Cell Size

#define COLLECTION_CELL_WIDTH 54

#define COLLECTION_CELL_HEIGHT 54


#endif
