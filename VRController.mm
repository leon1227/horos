/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


/*

MODIFICATION HISTORY

	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).

  
*/


#import "VRController.h"
#import "DCMView.h"
#import "dicomFile.h"
#import "NSFullScreenWindow.h"
#import "Papyrus3/Papyrus3.h"
#import "BrowserController.h"
#include <Accelerate/Accelerate.h>
#import "iPhoto.h"
#import "DICOMExport.h"
#import "VRFlyThruAdapter.h"
#import "DicomImage.h"
#import "VRView.h"
#import "ROI.h"
#import "ROIVolume.h"
#import "ROIVolumeManagerController.h"

extern "C"
{
extern BrowserController *browserWindow;
extern NSString * documentsDirectory();
extern NSString* convertDICOM( NSString *inputfile);
}

static NSString* 	VRStandardToolbarIdentifier		= @"VR Toolbar Identifier";
static NSString* 	VRPanelToolbarIdentifier		= @"VRPanel Toolbar Identifier";

static NSString*	QTExportToolbarItemIdentifier 	= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier 	= @"iPhoto.icns";
static NSString*	QTExportVRToolbarItemIdentifier = @"QTExportVR.icns";
static NSString*	StereoIdentifier				= @"Stereo.icns";
static NSString*	CaptureToolbarItemIdentifier 	= @"Capture.icns";
static NSString*	CroppingToolbarItemIdentifier 	= @"Cropping.icns";
static NSString*	OrientationToolbarItemIdentifier= @"OrientationWidget.tiff";
static NSString*	ToolsToolbarItemIdentifier		= @"Tools";
static NSString*	WLWWToolbarItemIdentifier		= @"WLWW";
static NSString*	LODToolbarItemIdentifier		= @"LOD";
static NSString*	BlendingToolbarItemIdentifier   = @"2DBlending";
static NSString*	MovieToolbarItemIdentifier		= @"Movie";
static NSString*	ExportToolbarItemIdentifier		= @"Export.icns";
static NSString*	MailToolbarItemIdentifier		= @"Mail.icns";
static NSString*	ShadingToolbarItemIdentifier	= @"Shading";
static NSString*	EngineToolbarItemIdentifier		= @"Engine";
static NSString*	PerspectiveToolbarItemIdentifier= @"Perspective";
static NSString*	ResetToolbarItemIdentifier		= @"Reset.tiff";
static NSString*	RevertToolbarItemIdentifier		= @"Revert.tiff";
static NSString*	ModeToolbarItemIdentifier		= @"Mode";
static NSString*	FlyThruToolbarItemIdentifier	= @"FlyThru.tif";
static NSString*	ScissorStateToolbarItemIdentifier	= @"ScissorState";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.tiff";
static NSString*	OrientationsViewToolbarItemIdentifier		= @"OrientationsView";
static NSString*	ConvolutionViewToolbarItemIdentifier		= @"ConvolutionView";

@implementation VRController


- (IBAction) setOrientation:(id) sender
{
	switch( [[sender selectedCell] tag])
	{
		case 0:
			[view axView: self];
		break;
		
		case 1:
			[view coView: self];
		break;
		
		case 2:
			[view saView: self];
		break;
		
		case 3:
			[view saViewOpposite: self];
		break;
	}
}

-(void) revertSeries:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"revertSeriesNotification" object: pixList[ curMovieIndex] userInfo: 0L];
}

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[OpacityPopup menu] numberOfItems];
    while(i-- > 0) [[OpacityPopup menu] removeItemAtIndex:0];
	
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
	[[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[OpacityPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
    }
    [[OpacityPopup menu] addItem: [NSMenuItem separatorItem]];
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];

	[[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
}


-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    i = [[wlwwPopup menu] numberOfItems];
    while(i-- > 0) [[wlwwPopup menu] removeItemAtIndex:0];
    
/*    item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"Presets"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[wlwwPopup menu] addItem:item];
    [item release]; */
    
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];

	[[[wlwwPopup menu] itemAtIndex:0] setTitle:curWLWWMenu];
}



-(void) LODsliderAction:(id) sender
{
    [view setLOD:[sender floatValue]];
}

- (void) windowDidLoad
{
    [self setupToolbar];
//	[self createContextualMenu];
}

-(ViewerController*) blendingController
{
	return blendingController;
}

- (void) blendingSlider:(id) sender
{
	[view setBlendingFactor: [sender floatValue]];
	
	[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) 100.0*([sender floatValue]) / 256.0]];	//(float) ([sender floatValue]+256.) / 5.12]];
}

-(void) updateBlendingImage
{
	Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
	float			iwl, iww;

	[[viewer2D imageView] blendingColorTables:&alphaTable :&redTable :&greenTable :&blueTable];
	
	[view setBlendingCLUT :redTable :greenTable :blueTable];
	
	[[blendingController imageView] getWLWW: &iwl :&iww];
	[view setBlendingWLWW :iwl :iww];
}

- (IBAction) applyConvolution:(id) sender
{
	[viewer2D ApplyConvString: [sender title]];
	[viewer2D applyConvolutionOnSource: self];
}

-(void) UpdateConvolutionMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu, *convMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    // Popup Menu

    i = [[convolutionMenu menu] numberOfItems];
    while(i-- > 0) [[convolutionMenu menu] removeItemAtIndex:0];
	
	[[convolutionMenu menu] addItemWithTitle: NSLocalizedString( @"Apply a filter", 0L) action:0L keyEquivalent:@""];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[convolutionMenu menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (applyConvolution:) keyEquivalent:@""];
    }
}


-(long) movieFrames { return maxMovieIndex;}

- (void) setMovieFrame: (long) l
{
	curMovieIndex = l;
	[moviePosSlider setIntValue: curMovieIndex];
	
	[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes] showWait: NO];
}

-(void) updateVolumeData: (NSNotification*) note
{
	long i;
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( [note object] == pixList[ i])
		{
			[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
		}
	}
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
	[self setMovieFrame:  [moviePosSlider intValue] ];
}

- (void) performMovieAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
    if( thisTime - lastMovieTime > 1.0 / [movieRateSlider floatValue])
    {
        val = curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val >= maxMovieIndex) val = 0;
		
		[self setMovieFrame: val];
		
        lastMovieTime = thisTime;
    }
}

- (void) MoviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
        
        [moviePlayStop setTitle: @"Play"];
        
		[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
    }
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [moviePlayStop setTitle: @"Stop"];
    }
}

-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData
{
	[pix retain];
	pixList[ maxMovieIndex] = pix;
	
	[vData retain];
	volumeData[ maxMovieIndex] = vData;
	
	maxMovieIndex++;
	
	[moviePosSlider setMaxValue:maxMovieIndex-1];
	[moviePosSlider setNumberOfTickMarks:maxMovieIndex];

	[movieRateSlider setEnabled: YES];
	[moviePosSlider setEnabled: YES];
	[moviePlayStop setEnabled: YES];
	
	[self computeMinMax];
}

- (float) blendingMinimumValue;
{
	return blendingMinimumValue;
}

- (float) blendingMaximumValue;
{
	return blendingMaximumValue;
}

- (float) minimumValue;
{
	return minimumValue;
}

- (float) maximumValue;
{
	return maximumValue;
}

- (short)curMovieIndex;
{
	return curMovieIndex;
}

- (BOOL)is4D;
{
	return (maxMovieIndex > 1);
}

-(NSMutableArray*) pixList { return pixList[0];}

-(NSMutableArray*) curPixList { return pixList[ curMovieIndex];}

- (NSString*) style
{
	return style;
}

-(void) awakeFromNib
{
	if( [style isEqualToString:@"panel"])
	{
		[self setShouldCascadeWindows: NO];
		[[self window] setFrameAutosaveName:@"3D Panel"];
		[[self window] setFrameUsingName:@"3D Panel"];
	}
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
	[self initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC style:@"standard" mode:@"VR"];
}

- (void) computeMinMax
{
	maximumValue = minimumValue = [[pixList[ 0] objectAtIndex: 0] maxValueOfSeries];
	
	blendingMinimumValue = [[blendingPixList objectAtIndex: 0] minValueOfSeries];
	blendingMaximumValue = [[blendingPixList objectAtIndex: 0] maxValueOfSeries];
	
	int i;
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( maximumValue < [[pixList[ i] objectAtIndex: 0] maxValueOfSeries]) maximumValue = [[pixList[ i] objectAtIndex: 0] maxValueOfSeries];
		if( minimumValue > [[pixList[ i] objectAtIndex: 0] minValueOfSeries]) minimumValue = [[pixList[ i] objectAtIndex: 0] minValueOfSeries];
	}
	
	NSLog( @"min: %f max: %f", minimumValue, maximumValue);
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC style:(NSString*) m mode:(NSString*) renderingMode
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	DCMPix			*firstObject = [pix objectAtIndex: 0];
	
	// MEMORY TEST: The renderer needs to have the volume in short
	{
		char	*testPtr = (char*) malloc( [firstObject pwidth] * [firstObject pheight] * [pix count] * sizeof( short) + 4UL * 1024UL * 1024UL);
		if( testPtr == 0L)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			return 0L;
		}
		else
		{
			free( testPtr);
		}
	}
	
//	// ** RESAMPLE START
//	

//	WaitRendering *www = [[WaitRendering alloc] init:@"Resampling 3D data..."];
//	[www start];
//	
//	NSMutableArray		*newPix = [NSMutableArray array], *newFiles = [NSMutableArray array];
//	NSData				*newData = 0L;
//	
//	if( [ViewerController resampleDataFromPixArray:pix fileArray:f inPixArray:newPix fileArray:newFiles data:&newData withXFactor:2 yFactor:2 zFactor:2] == NO)
//	{
//		NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return 0L;
//	}
//	else
//	{
//		pix = newPix;
//		f = newFiles;
//		vData = newData;
//		
//		firstObject = [pix objectAtIndex: 0];
//	}
//	
//	[www end];
//	[www close];
//	[www release];
//	
//	// ** RESAMPLE END
			
	style = [m retain];
	_renderingMode = [renderingMode retain];
	// BY DEFAULT TURN OFF OPENGL ENGINE !
	[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"MAPPERMODEVR"];
	
	for( i = 0; i < 100; i++) undodata[ i] = 0L;
	
	flyThruController = 0L;
	
	curMovieIndex = 0;
	maxMovieIndex = 1;
	
	fileList = f;
	[fileList retain];
	
	pixList[0] = pix;
	volumeData[0] = vData;
	
    float sliceThickness = fabs( [firstObject sliceInterval]);
		
	  //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
		testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil), NSLocalizedString( @"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil),NSLocalizedString( @"OK",nil), nil, nil);
			return 0L;
		}
    }
    
    // CHECK IMAGE SIZE
    for( i =0 ; i < [pixList[0] count]; i++)
    {
        if( [firstObject pwidth] != [[pixList[0] objectAtIndex:i] pwidth]) err = -1;
        if( [firstObject pheight] != [[pixList[0] objectAtIndex:i] pheight]) err = -1;
    }
    if( err)
    {
        NSRunCriticalAlertPanel(NSLocalizedString( @"Images size",nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...",nil),NSLocalizedString( @"OK",nil), nil, nil);
        return 0L;
    }
    
    // CHECK IMAGE SIZE
//	if( testInterval)
//	{
//		float prevLoc = [firstObject sliceLocation];
//		for( i = 1 ; i < [pixList count]; i++)
//		{
//			if( fabs( sliceThickness - fabs( [[pixList objectAtIndex:i] sliceLocation] - prevLoc)) > 0.1) err = -1;
//			prevLoc = [[pixList objectAtIndex:i] sliceLocation];
//		}
//		if( err)
//		{
//			if( NSRunCriticalAlertPanel( @"Slices location",  @"Slice thickness/interval is not exactly equal for all images. This could distord the 3D reconstruction...", @"Continue", @"Cancel", nil) != NSAlertDefaultReturn) return 0L;
//			err = 0;
//		}
//	}

	[pixList[0] retain];
	[volumeData[0] retain];
    viewer2D = [vC retain];
	
	blendingController = bC;
	if( blendingController) blendingPixList = [blendingController pixList];
	
	// Find Minimum Value
	if( [firstObject isRGB] == NO) [self computeMinMax];
	else minimumValue = 0;

	if( [style isEqualToString:@"standard"])
		self = [super initWithWindowNibName:@"VR"];
	else
	{
		self = [super initWithWindowNibName:@"VRPanel"];
	}
    [[self window] setDelegate:self];
    
    err = [view setPixSource:pixList[0] :(float*) [volumeData[0] bytes]];
    if( err != 0)
    {
		NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
        [self dealloc];
        return 0L;
    }
	
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
		
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) 100.*([blendingSlider floatValue]) / 256.]];
		
		[self updateBlendingImage];
	}
	
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	
	roi2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	sliceNumber2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	x2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	y2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	z2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	
	if (viewer2D)
	{		
		long i, j;
		float x, y, z;
		NSMutableArray	*curRoiList;
		ROI	*curROI;
		
		for(i=0; i<[[[viewer2D imageView] dcmPixList] count]; i++)
		{
			curRoiList = [[viewer2D roiList] objectAtIndex: i];
			for(j=0; j<[curRoiList count];j++)
			{
				curROI = [curRoiList objectAtIndex:j];
				if ([curROI type] == t2DPoint)
				{
					float location[ 3 ];
					
					[[[viewer2D pixList] objectAtIndex: i] convertPixX: [[[curROI points] objectAtIndex:0] x] pixY: [[[curROI points] objectAtIndex:0] y] toDICOMCoords: location];
					
					x = location[ 0 ];
					y = location[ 1 ];
					z = location[ 2 ];

					// add the 3D Point to the SR view
					[[self view] add3DPoint:  x : y : z];
					// add the 2D Point to our list
					[roi2DPointsArray addObject:curROI];
					[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:i]];
					[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
					[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
					[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
				}
			}
		}
	}

	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver: self
		selector: @selector(remove3DPoint:)
		name: @"removeROI"
		object: nil];
	[nc addObserver: self
		selector: @selector(add3DPoint:)
		//name: @"roiChange"
		name: @"roiSelected"
		object: nil];

    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(updateVolumeData:)
               name: @"updateVolumeData"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	
	curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: @"UpdateOpacityMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
	
	[nc addObserver: self
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];

	[nc addObserver: self
           selector: @selector(UpdateConvolutionMenu:)
               name: @"UpdateConvolutionMenu"
             object: nil];
	 [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: NSLocalizedString( @"No Filter", 0L) userInfo: 0L];
			
	 [nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
	
	//should we always zoom the Window?
	//if( [style isEqualToString:@"standard"])
	//	[[self window] performZoom:self];
	
	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled: NO];
	
//	[[enginePopup menu] setAutoenablesItems : NO];
//	[[[enginePopup menu] itemAtIndex: 3] setEnabled: NO];
	[[[enginePopup menu] itemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]+1] setState:NSOnState];
	
	[self updateEngine];
	
	[view updateScissorStateButtons];
	
	roiVolumes = [[NSMutableArray alloc] initWithCapacity:0];
#ifdef roi3Dvolume
	[self computeROIVolumes];
	[self displayROIVolumes];
#endif

	// allow bones removal only for CT scans
	if(![[viewer2D modality] isEqualToString:@"CT"])
	{
		[[toolsMatrix cellWithTag:21] setEnabled:NO];
	}
	else
	{
		[[toolsMatrix cellWithTag:21] setEnabled:YES];
	}

	if( [renderingMode isEqualToString:@"MIP"])
		[self setModeIndex: 1];
		
	if( [style isEqualToString:@"panel"])
	{
		[view setRotate: YES];
		[view setLOD: 1.0];
		[LODSlider setIntValue: 1];
	}
		
    return self;
}


-(NSString*) getUniqueFilenameScissorState
{
	NSString		*path = [documentsDirectory() stringByAppendingString:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingFormat: @"VR3DScissor-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]];
}

-(void) save3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingString:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingFormat: @"VRMIP-%d-%@", [view mode], [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]];
	
	NSMutableDictionary *dict = [view get3DStateDictionary];
	[dict setObject:curCLUTMenu forKey:@"CLUTName"];
	[dict setObject:curOpacityMenu forKey:@"OpacityName"];
	
	if( [viewer2D postprocessed] == NO)
		[dict writeToFile:str atomically:YES];
}

-(void) load3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingString:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	
	NSString	*str = [path stringByAppendingFormat: @"VRMIP-%d-%@", [view mode], [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
	
	if( [viewer2D postprocessed]) dict = 0L;
	
	[view set3DStateDictionary:dict];
	if( [dict objectForKey:@"CLUTName"]) [self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
	else if([view mode] == 0 && [[pixList[ 0] objectAtIndex:0] isRGB] == NO) [self ApplyCLUTString:@"VR Muscles-Bones"];	//For VR mode only
	
	if( [dict objectForKey:@"OpacityName"]) [self ApplyOpacityString:[dict objectForKey:@"OpacityName"]];
	else if([view mode] == 0 && [[pixList[ 0] objectAtIndex:0] isRGB] == NO) [self ApplyOpacityString:NSLocalizedString(@"Logarithmic Inverse Table", nil)];		//For VR mode only
	
	if( [view shading]) [shadingCheck setState: NSOnState];
	else [shadingCheck setState: NSOffState];
	
	float ambient, diffuse, specular, specularpower;
	
	[view getShadingValues: &ambient :&diffuse :&specular :&specularpower];
	[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.1f\nDiffuse: %2.1f\nSpecular :%2.1f-%2.1f", ambient, diffuse, specular, specularpower]];
}

- (void) applyScissor : (NSArray*) object
{
	long		x, i				= [[object objectAtIndex: 0] intValue];
	long		stackOrientation	= [[object objectAtIndex: 1] intValue];
	long		c					= [[object objectAtIndex: 2] intValue];
	ROI*		roi					= [object objectAtIndex: 3];
	BOOL		blendedSeries		= [[object objectAtIndex: 4] intValue];
	
	if( blendedSeries)
	{
		switch( stackOrientation)
		{
			case 2:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[blendingPixList objectAtIndex: i] fillROI: roi :minimumValue :-999999 :999999 :YES :2 :i];
				else [[blendingPixList objectAtIndex: i] fillROI: roi :minimumValue :-999999 :999999 :NO :2 :i];
				break;
				
			case 1:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[blendingPixList objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :YES :1 :i];
				else [[blendingPixList objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :NO :1 :i];
				break;
				
			case 0:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[blendingPixList objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :YES :0 : i];
				else [[blendingPixList objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :NO :0 :i];
				break;
		}
	}
	else
	{
		BOOL test = NO;
		
		 if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) test = YES;
	
		for( x = 0; x < maxMovieIndex; x++)
		{
			switch( stackOrientation)
			{
				case 2:
					if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: i] fillROI: roi :minimumValue :-999999 :999999 :YES :2 :i];
					else [[pixList[ x] objectAtIndex: i] fillROI: roi :minimumValue :-999999 :999999 :NO :2 :i  :test];
					break;
					
				case 1:
					if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :YES :1 :i];
					else [[pixList[ x] objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :NO :1 :i  :test];
					break;
					
				case 0:
					if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :YES :0 : i];
					else [[pixList[ x] objectAtIndex: 0] fillROI: roi :minimumValue :-999999 :999999 :NO :0 :i  :test];
					break;
			}
		}
	}
}

- (void) prepareUndo
{
	long i;
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
		float*	data = (float*) [volumeData[ i] bytes];
		long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( short);
		
		if( undodata[ i] == 0L)
		{
			undodata[ i] = (float*) malloc( memSize);
		}
		
		if( undodata[ i])
		{
			vImage_Buffer srcf, dst16;
			
			srcf.height = [firstObject pheight] * [pixList[ i] count];
			srcf.width = [firstObject pwidth];
			srcf.rowBytes = [firstObject pwidth] * sizeof(float);
			
			dst16.height = [firstObject pheight] * [pixList[ i] count];
			dst16.width = [firstObject pwidth];
			dst16.rowBytes = [firstObject pwidth] * sizeof(short);
			
			dst16.data = undodata[ i];
			srcf.data = data;
			
			vImageConvert_FTo16U( &srcf, &dst16, -[view offset], 1./[view valueFactor], 0);
			
//			memcpy( undodata[ i], data, memSize);
		}
		else NSLog(@"Undo failed... not enough memory");
	}
}

- (IBAction) undo:(id) sender
{
	long i;
	
	NSLog(@"undo");
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( undodata[ i])
		{
			DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
			float*	data = (float*) [volumeData[ i] bytes];
//			long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
//			float*	cpy = data;
			
			vImage_Buffer src16, dstf;
			
			src16.height = [firstObject pheight] * [pixList[ i] count];
			src16.width = [firstObject pwidth];
			src16.rowBytes = [firstObject pwidth] * sizeof(short);
			
			dstf.height = [firstObject pheight] * [pixList[ i] count];
			dstf.width = [firstObject pwidth];
			dstf.rowBytes = [firstObject pwidth] * sizeof(float);
			
			dstf.data = data;
			src16.data = undodata[ i];
			
			vImageConvert_16UToF( &src16, &dstf, -[view offset], 1./[view valueFactor], 0);
			
			//BlockMoveData( undodata[ i], data, memSize);
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ i] userInfo: 0];
	}
}

- (NSArray*) fileList
{
	return fileList;
}

-(void) dealloc
{
	long i;

    NSLog(@"Dealloc VRController");
	
	[style release];
	
	// Release Undo system
	for( i = 0; i < maxMovieIndex; i++)
	{
		DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
		
		if( undodata[ i])
		{
			free( undodata[ i]);
		}
	}
	
	[self save3DState];
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	for( i = 0; i < maxMovieIndex; i++)
	{
		[pixList[ i] release];
		[volumeData[ i] release];
	}
	[fileList release];
	[toolbar setDelegate: 0L];
	[toolbar release];
	
	// 3D Points
	[roi2DPointsArray release];
	[sliceNumber2DPointsArray release];
	[x2DPointsArray release];
	[y2DPointsArray release];
	[z2DPointsArray release];
	[viewer2D release];
	[roiVolumes release];
	[_renderingMode release];
	[super dealloc];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer2D)
	{
		[self offFullScreen];
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
	
	if( movieTimer)
	{
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
    [[self window] setDelegate:nil];
	
    [self release];
}

-(NSMatrix*) toolsMatrix
{
	return toolsMatrix;
}

-(void) setDefaultTool:(id) sender
{
	//Sender may be matrix or menu. LP 12/3/05
	
	int tag;
	if ([sender isKindOfClass:[NSMatrix class]])
		tag = [[sender selectedCell] tag];
	else
		tag = [sender tag];
    
    if( tag >= 0)
    {
        [self setCurrentTool:tag];
    }

}

- (void) setCurrentTool:(short) newTool
{
	[view setCurrentTool: newTool];
		//select matrix tool
	[toolsMatrix selectCellWithTag:newTool];
}


- (void) setWLWW:(float) iwl :(float) iww
{
	[view setWLWW: iwl : iww];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
	[view getWLWW: iwl : iww];
}

- (void) ApplyWLWW:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Delete a WL/WW preset",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'?", [sender title]]);
    }
    else
    {
		[self applyWLWWForString:[sender title]];
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
}

- (void)applyWLWWForString:(NSString *)menuString{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", 0L)] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", 0L)] == YES)
		{
			[view setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		}
		else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", 0L)] == YES)
		{
			[view setWLWW:0 :0];
		}
		else
		{
			NSArray    *value;
			
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey:menuString];
			
			[view setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];
		
	if( curWLWWMenu != menuString)
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}

}

static float	savedambient, saveddiffuse, savedspecular, savedspecularpower;

- (IBAction) resetShading:(id) sender
{
	float ambient, diffuse, specular, specularpower;
	
	ambient = 0.15;
	diffuse = 0.9;
	specular = 0.3;
	specularpower = 15;
	
	[[shadingForm cellAtIndex: 0] setFloatValue: ambient];
	[[shadingForm cellAtIndex: 1] setFloatValue: diffuse];
	[[shadingForm cellAtIndex: 2] setFloatValue: specular];
	[[shadingForm cellAtIndex: 3] setFloatValue: specularpower];
	
	[self endShadingEditing: sender];
}

- (IBAction) endShadingEditing:(id) sender
{
    if( [sender tag])   //User clicks OK Button
    {
		float ambient, diffuse, specular, specularpower;
		
//		NSLog(@"ambient: %@, diffuse: %@, specular: %@, specularpower: %@", [[shadingForm cellAtIndex: 0] stringValue], [[shadingForm cellAtIndex: 1] stringValue], [[shadingForm cellAtIndex: 2] stringValue], [[shadingForm cellAtIndex: 3] stringValue]);
		
		ambient = [[shadingForm cellAtIndex: 0] floatValue];
		diffuse = [[shadingForm cellAtIndex: 1] floatValue];
		specular = [[shadingForm cellAtIndex: 2] floatValue];
		specularpower = [[shadingForm cellAtIndex: 3] floatValue];
		
//		NSLog(@"ambient: %f, diffuse: %f, specular: %f, specularpower: %f", ambient, diffuse, specular, specularpower);
		
		[view setShadingValues: ambient :diffuse :specular :specularpower];
		[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", ambient, diffuse, specular, specularpower]];
    }
	
	if( [sender tag] == 0)
	{
		[view setShadingValues: savedambient :saveddiffuse :savedspecular :savedspecularpower];
		[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", savedambient, saveddiffuse, savedspecular, savedspecularpower]];
	}
	
	[view setNeedsDisplay: YES];
	
	if( [sender tag] == 2) return;
	
    [shadingEditWindow orderOut:sender];
    
    [NSApp endSheet:shadingEditWindow returnCode:[sender tag]];

}

- (IBAction) editShadingValues:(id) sender
{
	[view getShadingValues: &savedambient :&saveddiffuse :&savedspecular :&savedspecularpower];

	[[shadingForm cellAtIndex: 0] setFloatValue: savedambient];
	[[shadingForm cellAtIndex: 1] setFloatValue: saveddiffuse];
	[[shadingForm cellAtIndex: 2] setFloatValue: savedspecular];
	[[shadingForm cellAtIndex: 3] setFloatValue: savedspecularpower];

    [NSApp beginSheet: shadingEditWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (void) AddCurrentWLWW:(id) sender
{
	float iww, iwl;
	
    [view getWLWW:&iwl :&iww];
    
    [wl setStringValue:[NSString stringWithFormat:@"%0.f", iwl]];
    [ww setStringValue:[NSString stringWithFormat:@"%0.f", iww]];
    
	[newName setStringValue: @"Unnamed"];
	
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


-(void) ApplyCLUTString:(NSString*) str
{
	if( str == 0L) return;
	
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
	{
		[view setCLUT: 0L :0L :0L];
		[view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str];
		if( aCLUT)
		{
			array = [aCLUT objectForKey:@"Red"];
			for( i = 0; i < 256; i++)
			{
				red[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Green"];
			for( i = 0; i < 256; i++)
			{
				green[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Blue"];
			for( i = 0; i < 256; i++)
			{
				blue[i] = [[array objectAtIndex: i] longValue];
			}
			
			[view setCLUT:red :green: blue];
			
			if( [curCLUTMenu isEqualToString: NSLocalizedString( @"B/W Inverse", 0L)] || [curCLUTMenu isEqualToString:( @"B/W Inverse")])
				[view changeColorWith: [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
			else 
				[view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
		}
	}
}



-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
	NSArray				*array;
	long				i;
	
	if( str == 0L) return;
	
	if( curOpacityMenu != str)
	{
		[curOpacityMenu release];
		curOpacityMenu = [str retain];
	}
	
	if( [str isEqualToString:@"Linear Table"])
	{
		[view setOpacity:[NSArray array]];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if( aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[view setOpacity:array];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle: curOpacityMenu];
		}
	}
}



- (void) updateEngine
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"])
	{
		case 0:	// RAY CAST
			[LODSlider setEnabled: YES];
			[[modeMatrix cellWithTag:1] setEnabled: YES];
		break;
		
		case 1:	// TEXTURE
			[LODSlider setEnabled: NO];
			[[modeMatrix cellWithTag:1] setEnabled: NO];
			[self setModeIndex: 0];
		break;
		
		case 2:
			[LODSlider setEnabled: NO];
			[[modeMatrix cellWithTag:1] setEnabled: NO];
			[self setModeIndex: 0];
		break;
	}
}

- (NSString *)renderingMode{
	return _renderingMode;
}

- (void)setRenderingMode:(NSString *)renderingMode{
	if ([renderingMode isEqualToString:@"VR"] || [renderingMode isEqualToString:@"MIP"]) {
		if ([renderingMode isEqualToString:@"MIP"])
			[self setModeIndex:1];
		else if ([renderingMode isEqualToString:@"VR"])
			[self setModeIndex:0];
	}
}

- (IBAction) setModeIndex:(long) val
{
	if( val == 1)	// MIP -> Turn Off Texture Mapping
	{
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] != 0)
		{
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"MAPPERMODEVR"];
			[enginePopup selectItemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]+1];
			[self setEngine: self];
		}
	}
	
	[modeMatrix selectCellWithTag: val];
	[self setMode: modeMatrix];
}

- (IBAction) setMode:(id) sender
{
	int tag;
	if ([sender isKindOfClass:[NSMatrix class]])
		tag = [[sender selectedCell] tag];
	else {
		tag = [sender tag];
		[modeMatrix setState:1 atRow:tag column:0];
	}
	[view setMode: tag];
	[view setBlendingMode: tag];
	
	if( tag == 1)
	{
		[_renderingMode release];
		_renderingMode = [@"MIP" retain];
		[shadingCheck setEnabled : NO];
	}
	else
	{
		[_renderingMode release];
		_renderingMode = [@"VR" retain];
		[shadingCheck setEnabled : YES];
	}

}

- (IBAction) setEngine:(id) sender
{
	long i;
	
	for( i = 0 ; i < [[enginePopup menu] numberOfItems]; i++)
	{
		[[[enginePopup menu] itemAtIndex: i] setState: NSOffState];
	}
	
	[[enginePopup selectedItem] setState: NSOnState];

//	[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];

	[view setEngine: [[enginePopup selectedItem] tag]];
	[view setBlendingEngine: [[enginePopup selectedItem] tag]];
	
//	[[NSUserDefaults standardUserDefaults] setInteger: [[enginePopup selectedItem] tag] forKey: @"MAPPERMODEVR"];
	
	[self updateEngine];
}

- (IBAction) AddOpacity:(id) sender
{
	NSDictionary		*aCLUT;
	NSArray				*array;
	long				i;
	unsigned char		red[256], green[256], blue[256];

	aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
	if( aCLUT)
	{
		array = [aCLUT objectForKey:@"Red"];
		for( i = 0; i < 256; i++)
		{
			red[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Green"];
		for( i = 0; i < 256; i++)
		{
			green[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Blue"];
		for( i = 0; i < 256; i++)
		{
			blue[i] = [[array objectAtIndex: i] longValue];
		}
		
		[OpacityView setCurrentCLUT:red :green: blue];
	}
	
	[OpacityName setStringValue: NSLocalizedString(@"Unnamed", nil)];
	
    [NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void) bestRendering:(id) sender
{
	[view bestRendering: sender];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
	
	if( [style isEqualToString:@"standard"]) toolbar = [[NSToolbar alloc] initWithIdentifier: VRStandardToolbarIdentifier];
    else toolbar = [[NSToolbar alloc] initWithIdentifier: VRPanelToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton: [style isEqualToString:@"panel"]];
	[[[self window] toolbar] setVisible: [style isEqualToString:@"standard"]];
    
//    [window makeKeyAndOrderFront:nil];
}

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
     if ([itemIdent isEqualToString: QTExportVRToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a Quicktime VR file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
    }
	else if ([itemIdent isEqualToString: StereoIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
	[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(SwitchStereoMode:)];
    }
	else if ([itemIdent isEqualToString: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Email",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqualToString: RevertToolbarItemIdentifier]) {
		 
		 [toolbarItem setLabel: NSLocalizedString(@"Revert",nil)];
		 [toolbarItem setPaletteLabel: NSLocalizedString(@"Revert",nil)];
		 [toolbarItem setToolTip: NSLocalizedString(@"Revert series by re-loading images from disk",nil)];
		 [toolbarItem setImage: [NSImage imageNamed: RevertToolbarItemIdentifier]];
		 [toolbarItem setTarget: self];
		 [toolbarItem setAction: @selector(revertSeries:)];
	 }
	else if ([itemIdent isEqualToString: ShadingToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Shading",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Shading",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Shading Properties",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: shadingView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([shadingView frame]), NSHeight([shadingView frame]))];
    }
	else if ([itemIdent isEqualToString: EngineToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Engine",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Engine",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Engine",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: engineView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
    }
	else if ([itemIdent isEqualToString: PerspectiveToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Perspective",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Perspective",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Perspective Properties",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: perspectiveView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([perspectiveView frame]), NSHeight([perspectiveView frame]))];
    }
	else if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqualToString: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setToolTip:NSLocalizedString(@"Export this image to iPhoto",nil)];
	[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel:NSLocalizedString( @"DICOM File",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString(@"Save as DICOM",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
//	else if ([itemIdent isEqualToString: SendToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: @"Send DICOM"];
//	[toolbarItem setPaletteLabel: @"Send DICOM"];
//        [toolbarItem setToolTip: @"Send this image to a DICOM node"];
//	[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
//	[toolbarItem setTarget: self];
//	[toolbarItem setAction: @selector(exportDICOMPACS:)];
//    }
	else if ([itemIdent isEqualToString: CroppingToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Crop",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube",nil)];
	[toolbarItem setToolTip:NSLocalizedString(@"Show and manipulate cropping cube",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(showCropCube:)];
    }
	else if ([itemIdent isEqualToString: OrientationToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Orientation",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation Cube",nil)];
	[toolbarItem setToolTip:NSLocalizedString(@"Show orientation cube",nil)];
	[toolbarItem setImage: [NSImage imageNamed: OrientationToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(switchOrientationWidget:)];
    }
	else if ([itemIdent isEqualToString: CaptureToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Best Rendering",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Render this image at the best resolution",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(bestRendering:)];
    }
    else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT & Opacity",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"WL/WW & CLUT & Opacity",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: WLWWView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
	[[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
	else if([itemIdent isEqualToString: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"4D Player",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
	else if([itemIdent isEqualToString: OrientationsViewToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Orientations", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientations", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Orientations", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: OrientationsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
    }
	else if([itemIdent isEqualToString: ConvolutionViewToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Filters", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Filters", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Filters", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: convolutionView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
    }
	else if([itemIdent isEqualToString: ScissorStateToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"3D Scissor State", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Scissor State", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"3D Scissor State", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: scissorStateView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
    }
	else if([itemIdent isEqualToString: BlendingToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel:NSLocalizedString( @"Fusion",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: BlendingView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
	 else if([itemIdent isEqualToString: ModeToolbarItemIdentifier]) {
		 // Set up the standard properties 
		 [toolbarItem setLabel:NSLocalizedString( @"Rendering Mode",nil)];
		 [toolbarItem setPaletteLabel:NSLocalizedString( @"Rendering Mode",nil)];
		 [toolbarItem setToolTip: NSLocalizedString(@"Rendering Mode",nil)];
		 
		 // Use a custom view, a text field, for the search item 
		 [toolbarItem setView: modeView];
		 [toolbarItem setMinSize:NSMakeSize(NSWidth([modeView frame]), NSHeight([modeView frame]))];
	 }
	else if([itemIdent isEqualToString: LODToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Level of Detail",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Level of Detail",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"Change Level of Detail",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: LODView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
     else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the mouse function",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	
	else if([itemIdent isEqualToString: FlyThruToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(flyThruControllerInit:)];
    }
	else if ([itemIdent isEqualToString: ROIManagerToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"ROI Manager",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"ROI Manager",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"ROI Manager",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(roiGetManager:)];
    }
	else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
	
     return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    
	if( [style isEqualToString:@"standard"])
		return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
												ModeToolbarItemIdentifier,
												WLWWToolbarItemIdentifier,
												LODToolbarItemIdentifier,
												CaptureToolbarItemIdentifier,
												CroppingToolbarItemIdentifier,
												OrientationToolbarItemIdentifier,
												ShadingToolbarItemIdentifier,
												EngineToolbarItemIdentifier,
												PerspectiveToolbarItemIdentifier,
												ConvolutionViewToolbarItemIdentifier,
												BlendingToolbarItemIdentifier,
												MovieToolbarItemIdentifier,
												NSToolbarFlexibleSpaceItemIdentifier,
												QTExportToolbarItemIdentifier,
												QTExportVRToolbarItemIdentifier,
												OrientationsViewToolbarItemIdentifier,
												ResetToolbarItemIdentifier,
												RevertToolbarItemIdentifier,
												ExportToolbarItemIdentifier,
												FlyThruToolbarItemIdentifier,
												nil];
	else
		return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
												ModeToolbarItemIdentifier,
												WLWWToolbarItemIdentifier,
												LODToolbarItemIdentifier,
												CaptureToolbarItemIdentifier,
												BlendingToolbarItemIdentifier,
												CroppingToolbarItemIdentifier,
												OrientationToolbarItemIdentifier,
												ShadingToolbarItemIdentifier,
												NSToolbarFlexibleSpaceItemIdentifier,
												QTExportToolbarItemIdentifier,
												OrientationsViewToolbarItemIdentifier,
												ResetToolbarItemIdentifier,
												ExportToolbarItemIdentifier,
												nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette
	
	if( [style isEqualToString:@"standard"])
		return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											WLWWToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											OrientationToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											EngineToolbarItemIdentifier,
											PerspectiveToolbarItemIdentifier,
											OrientationsViewToolbarItemIdentifier,
											ToolsToolbarItemIdentifier,
											ModeToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											StereoIdentifier,
											QTExportToolbarItemIdentifier,
											iPhotoToolbarItemIdentifier,
											QTExportVRToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
											ScissorStateToolbarItemIdentifier,
											ROIManagerToolbarItemIdentifier,
											ConvolutionViewToolbarItemIdentifier,
											nil];
	else
		return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											WLWWToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											OrientationToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											OrientationsViewToolbarItemIdentifier,
											QTExportToolbarItemIdentifier,
											iPhotoToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
//    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
//	[addedItem retain];
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
//	[removedItem retain];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
	
//	if ([[toolbarItem itemIdentifier] isEqualToString: CaptureToolbarItemIdentifier])
//		enable=!([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 1);
	
	if ([[toolbarItem itemIdentifier] isEqualToString: MovieToolbarItemIdentifier])
    {
        if(maxMovieIndex == 1) enable = NO;
    }
	
    return enable;
}

-(void) sendMail:(id) sender
{
	NSImage *im = [view nsimage:NO];
	
	[self sendMailImage: im];
	
	[im release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:@"3D VR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}


-(void) export2iPhoto:(id) sender
{
	iPhoto		*ifoto;
	NSImage		*im = [view nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	[im release];
	
	ifoto = [[iPhoto alloc] init];
	[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
	[ifoto release];
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:0L file:@"3D VR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

// Fly Thru

- (VRView*) view
{	
	return view;
}

- (IBAction) flyThruButtonMenu:(id) sender
{
	[flyThruController flyThruTag: [sender tag]];
}

- (IBAction) flyThruControllerInit:(id) sender
{
	//Only open 1 fly through controller
	NSArray *winList = [NSApp windows];
	long	i;
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"FlyThru"])
		{
			[[flyThruController window] makeKeyAndOrderFront :sender];
			return;
		}
	}
	
	FTAdapter = [[VRFlyThruAdapter alloc] initWithVRController: self];
	flyThruController = [[FlyThruController alloc] initWithFlyThruAdapter:FTAdapter];
	[FTAdapter release];
	[flyThruController loadWindow];
	[[flyThruController window] makeKeyAndOrderFront :sender];
	[flyThruController setWindow3DController: self];
}

- (FlyThruController *) flyThruController
{
	return flyThruController;
}

// 3D points
- (void) add2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D)
	{
		DCMPix *firstDCMPix = [[viewer2D pixList] objectAtIndex: 0];
		DCMPix *secondDCMPix = [[viewer2D pixList] objectAtIndex: 1];
		
		// find the slice where we want to add the point
		float sliceInterval = [secondDCMPix sliceLocation] - [firstDCMPix sliceLocation];
		long sliceNumber = (long) (z+0.5);
		
		if (sliceNumber>=0 && sliceNumber<[[viewer2D pixList] count])
		{
			// Create the new 2D Point ROI
			ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[firstDCMPix pixelSpacingX] :[firstDCMPix pixelSpacingY] :NSMakePoint( [firstDCMPix originX], [firstDCMPix originY])];
			NSRect irect;
			irect.origin.x = x;
			irect.origin.y = y;
			irect.size.width = irect.size.height = 0;
			[new2DPointROI setROIRect:irect];
			[[viewer2D imageView] roiSet:new2DPointROI];
			// add the 2D Point ROI to the ROI list
			[[[viewer2D roiList] objectAtIndex: sliceNumber] addObject: new2DPointROI];
			// add the ROI to our list
			[roi2DPointsArray addObject:new2DPointROI];
			[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:sliceNumber]];
			[x2DPointsArray addObject:[NSNumber numberWithFloat:x/[self factor]]];
			[y2DPointsArray addObject:[NSNumber numberWithFloat:y/[self factor]]];
			[z2DPointsArray addObject:[NSNumber numberWithFloat:z/[self factor]]];
			// notify the change
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object: new2DPointROI userInfo: 0L];
		}
	}
}

- (void) remove2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D)
	{
		long cur2DPointIndex = 0;
		BOOL found = NO;

		while(!found && cur2DPointIndex<[roi2DPointsArray count])
		{		
			if(	[[x2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==x/[self factor] 
				&& [[y2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==y/[self factor]
				&& [[z2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==z/[self factor])
			{
				found = YES;
			}
			else
			{
				cur2DPointIndex++;
			}
		}
		if (found && cur2DPointIndex<[roi2DPointsArray count])
		{
			// the 2D Point ROI object
			ROI * cur2DPoint;
			cur2DPoint = [roi2DPointsArray objectAtIndex:cur2DPointIndex];
			// remove 2D Point on 2D viewer2D
			[[[viewer2D roiList] objectAtIndex: [[sliceNumber2DPointsArray objectAtIndex:cur2DPointIndex] longValue]] removeObject:cur2DPoint];
			//notify
			[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:cur2DPoint userInfo: nil];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"updateView" object:0L userInfo: 0L];

			// remove 2D point in our list
			// done by remove3DPoint (through notification)
		}
	}
}

- (void) add3DPoint: (NSNotification*) note
{
	ROI	*addedROI = [note object];
	
	if ([roi2DPointsArray containsObject:addedROI])
	{
		[self remove3DPoint:note];
	}
	
	if ([addedROI type] == t2DPoint)
	{
		float location[3];
		double x, y, z;
			
		[[[viewer2D pixList] objectAtIndex:[[viewer2D imageView] curImage]] convertPixX: [[[addedROI points] objectAtIndex:0] x] pixY: [[[addedROI points] objectAtIndex:0] y] toDICOMCoords: location];
		
		x = location[0];
		y = location[1];
		z = location[2];

		// add the 3D Point to the SR view
		[[self view] add3DPoint: x : y : z];
		[[self view] setNeedsDisplay:YES];
		// add the 2D Point to our list
		[roi2DPointsArray addObject:addedROI];
		[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:[[viewer2D imageView] curImage]]];
		[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
		[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
		[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
	}
}

- (void) remove3DPoint: (NSNotification*) note
{
	ROI	*removedROI = [note object];
	
	if ([removedROI type] == t2DPoint) // 2D Points
	{
		// find 3D point
		float location[3];
		float x, y, z;
		
		[[[viewer2D pixList] objectAtIndex: 0] convertPixX: [[[removedROI points] objectAtIndex:0] x] pixY: [[[removedROI points] objectAtIndex:0] y] toDICOMCoords: location];

		x = location[0];
		y = location[1];
		z = location[2];

		long cur2DPointIndex = 0;
		BOOL found = NO;

		while(!found && cur2DPointIndex<[roi2DPointsArray count])
		{
			if(	[roi2DPointsArray objectAtIndex:cur2DPointIndex]==removedROI)
			{
				found = YES;
			}
			else
			{
				cur2DPointIndex++;
			}
		}
		
		if (found && cur2DPointIndex<[roi2DPointsArray count])
		{
			// remove the 3D Point in the SR view
			[[self view] remove3DPointAtIndex: cur2DPointIndex];
			[[self view] setNeedsDisplay:YES];
			// remove 2D point in our list
			[roi2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[sliceNumber2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[x2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[y2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[z2DPointsArray removeObjectAtIndex:cur2DPointIndex];
		}
	}
}

- (NSMutableArray*) roi2DPointsArray
{
	return roi2DPointsArray;
}

- (NSMutableArray*) sliceNumber2DPointsArray
{
	return sliceNumber2DPointsArray;
}

// contextual menu
- (void)createContextualMenu{
	NSMenu *contextual =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenu *submenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Mode", nil)];
	NSMenuItem *item, *subItem;
	int i = 0;
	
	//Reset Item
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reset", nil) action: @selector(resetImage:)  keyEquivalent:@""];
	[item setTag:i++];
	[item setTarget:view];
	[contextual addItem:item];
	[item release];
	
	//Revert
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Revert", nil) action: @selector(resetShading:)  keyEquivalent:@""];
	[item setTag:i++];
	[item setTarget:self];
	[contextual addItem:item];
	[item release];
	
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Render Mode", nil) action: nil keyEquivalent:@""];
	[contextual addItem:item];
	//add submenu
	[item setSubmenu:submenu];
		//Volume Render		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Volume Render", nil) action: @selector(setMode:) keyEquivalent:@""];
		[subItem setTag:0];
		[subItem setTarget:self];
		[submenu addItem:subItem];
		[subItem release];
		//MIP
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"MIP", nil) action: @selector(setMode:) keyEquivalent:@""];
		[subItem setTag:1];
		[subItem setTarget:self];
		[submenu addItem:subItem];
		[subItem release];
	[submenu release];
	[item release];
	
	//Best
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Best", nil) action: @selector(bestRendering:)  keyEquivalent:@""];
	[item setTag:i++];
	[item setTarget:view];
	//[item setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
	[contextual addItem:item];
	[item release];
	
	//crop
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Crop", nil) action: @selector(showCropCube:)  keyEquivalent:@""];
	//[item setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
	[item setTarget:view];
	[item setTag:i++];
	[contextual addItem:item];
	[item release];

	
	[contextual addItem:[NSMenuItem separatorItem]];
	
	NSMenu *mainMenu = [NSApp mainMenu];
    NSMenu *viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
    NSMenu *presetsMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
	NSMenu *menu = [presetsMenu copy];
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Window Width & Level", nil) action: nil keyEquivalent:@""];
	[item setSubmenu:menu];
	[contextual addItem:item];
	[item release];
	[menu release];
	
	[contextual addItem:[NSMenuItem separatorItem]];
	//tools
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *toolsSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	[item setSubmenu:toolsSubmenu];
	
	
	NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil), 
					NSLocalizedString(@"Move", nil), 
					NSLocalizedString(@"Magnify", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"Control Model", nil), 
					NSLocalizedString(@"Control Camera", nil),
					NSLocalizedString(@"ROI", nil), nil];
						
	NSArray *images = [NSArray arrayWithObjects: NSLocalizedString(@"WLWW", nil), 
					NSLocalizedString(@"Move", nil),
					NSLocalizedString(@"Zoom", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"3DRotate", nil),
					NSLocalizedString(@"3DRotateCamera", nil),					
					NSLocalizedString(@"Length", nil),
					NSLocalizedString(@"3DCut", nil),
					  nil];
					  
	NSArray *tags = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], 
					[NSNumber numberWithInt:1], 
					[NSNumber numberWithInt:2], 
					[NSNumber numberWithInt:3],
					[NSNumber numberWithInt:7], 
					[NSNumber numberWithInt:18], 
					[NSNumber numberWithInt:5], 
					[NSNumber numberWithInt:17],
					nil];
	
	
	NSEnumerator *titleEnumerator = [titles objectEnumerator];
	NSEnumerator *imageEnumerator = [images objectEnumerator];
	NSEnumerator *tagEnumerator = [tags objectEnumerator];
	NSString *title;
	while (title = [titleEnumerator nextObject]) {
		subItem = [[NSMenuItem alloc] initWithTitle:title action: @selector(setDefaultTool:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setImage:[NSImage imageNamed:[imageEnumerator nextObject]]];
		[subItem setTarget:self];
		[toolsSubmenu addItem:subItem];
		[subItem release];
	}
	[toolsSubmenu release];
	[item release];
	
	
	//View	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *viewSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", nil)];
	[item setSubmenu:viewSubmenu];
	
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Axial", nil) action: @selector(axView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: AxToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Right", nil) action: @selector(saView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Left", nil) action: @selector(saViewOpposite:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaOppositeToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Coronal", nil) action: @selector(coView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: CoToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
	[viewSubmenu release];
	[item release];
	
	
	//Export
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *exportSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Export", nil)];
	[item setSubmenu:exportSubmenu];
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime VR", nil)  action:@selector(exportQuicktime3DVR:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DICOM", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Email", nil)  action:@selector(sendMail:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"iPhoto", nil)  action:@selector(export2iPhoto:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		
	
	[exportSubmenu release];
	[item release];
	
	
	[view setMenu:contextual];
	[contextual release];
												
}

- (float) factor
{
	return [view factor];
}

// ROIs Volumes
#ifdef roi3Dvolume
- (void) computeROIVolumes
{
	int i;
	NSArray *roiNames = [viewer2D roiNames];
	[roiVolumes removeAllObjects];
	
	for(i=0; i<[roiNames count]; i++)
	{
		NSArray *roisWithCurrentName = [viewer2D roisWithName:[roiNames objectAtIndex:i]];
		ROIVolume *volume = [[[ROIVolume alloc] init] autorelease];
		[volume setFactor:[self factor]];
		[volume setROIList:roisWithCurrentName];
		if ([volume isVolume])
			[roiVolumes addObject:volume];
	}
}

- (NSMutableArray*) roiVolumes
{
	return roiVolumes;
}

//- (void) displayROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	//NSLog(@"[[roiVolumes objectAtIndex:index] name] : %@", [[roiVolumes objectAtIndex:index] name]);
//	viewRenderer->AddActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}
//
//- (void) hideROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->RemoveActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) displayROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->AddActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}
- (void) hideROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->RemoveActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

- (void) displayROIVolumes
{
	int i;
	for(i=0; i<[roiVolumes count]; i++)
	{
		if([[roiVolumes objectAtIndex:i] visible])
		{
			[self displayROIVolume:[roiVolumes objectAtIndex:i]];
		}
	}
}

- (IBAction) roiGetManager:(id) sender
{
	//NSLog(@"roiGetManager");
	//NSLog(@"-[roiVolumes count] : %d", [roiVolumes count]);
	BOOL	found = NO;
	NSArray *winList = [NSApp windows];
	long i;
	
	for(i = 0; i < [winList count]; i++)
	{
		if([[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROIVolumeManager"])
		{
			found = YES;
		}
	}
	if(!found)
	{
		ROIVolumeManagerController *manager = [[ROIVolumeManagerController alloc] initWithViewer: self];
		if(manager)
		{
			[manager showWindow:self];
			[[manager window] makeKeyAndOrderFront:self];
		}
	}
}
#endif

- (ViewerController*) viewer2D {return viewer2D;}

- (void) showWindow:(id) sender
{
	[super showWindow: sender];
	
	if( [style isEqualToString:@"panel"] == NO) [view squareView: self];
}

- (NSManagedObject *)currentStudy{
	return [viewer2D currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [viewer2D currentSeries];
}

- (NSManagedObject *)currentImage{
	return [viewer2D currentImage];
}

-(float)curWW{
	return [viewer2D curWW];
}

-(float)curWL{
	return [viewer2D curWL];
}
- (NSString *)curCLUTMenu{
	return curCLUTMenu;
}

@end
