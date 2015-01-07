//
//  LSAppDelegate.m
//  LayerSample
//
//  Created by Kevin Coleman on 6/10/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <LayerKit/LayerKit.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <HockeySDK/HockeySDK.h>
#import <LayerUIKit/LayerUIKit.h>
#import <MessageUI/MessageUI.h>
#import "LSAppDelegate.h"
#import "LSUIConversationListViewController.h"
#import "LSAPIManager.h"
#import "LSUtilities.h"
#import "LYRUIConstants.h"
#import "LSAuthenticationTableViewController.h"
#import "LSSplashView.h"
#import "LSLocalNotificationUtilities.h"
#import "SVProgressHUD.h" 

static NSString *const LSUserDefaultsLayerConfigurationURLKey = @"LAYER_CONFIGURATION_URL";
extern void LYRSetLogLevelFromEnvironment();
extern NSString *LYRApplicationDataDirectory(void);
extern dispatch_once_t LYRConfigurationURLOnceToken;

void LSTestResetConfiguration(void)
{
    extern dispatch_once_t LYRDefaultConfigurationDispatchOnceToken;
    
    NSString *archivePath = [LYRApplicationDataDirectory() stringByAppendingPathComponent:@"LayerConfiguration.plist"];
    [[NSFileManager defaultManager] removeItemAtPath:archivePath error:nil];
    
    // Ensure the next call through `LYRDefaultConfiguration` will reload
    LYRDefaultConfigurationDispatchOnceToken = 0;
    LYRConfigurationURLOnceToken = 0;
}

@interface LSAppDelegate () <LSAuthenticationTableViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) LSAuthenticationTableViewController *authenticationViewController;
@property (nonatomic) LSUIConversationListViewController *conversationListViewController;
@property (nonatomic) LSSplashView *splashView;
@property (nonatomic) LSEnvironment environment;
@property (nonatomic) LSLocalNotificationUtilities *localNotificationUtilities;
@property (nonatomic) MFMailComposeViewController *mailComposeViewController;

@end

@implementation LSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set up environment configuration
    if (!LSIsRunningTests()) {
        [self configureApplication:application forEnvironment:LYRUIProduction];
        [self initializeCrashlytics];
        [self initializeHockeyApp];
    } else {
        [self removeSplashView];
    }
    
    // Set root view controller
    [self setRootViewController];
    
    // Configure sample app UI appearance
    [self configureGlobalUserInterfaceAttributes];
    
    // Setup notifications
    [self registerNotificationObservers];
    
    // Conversation list view controller config
    _cellClass = [LYRUIConversationTableViewCell class];
    _rowHeight = 72;
    _allowsEditing = YES;
    _displaysConversationImage = NO;
    _displaysSettingsButton = YES;
    
    // Connect to Layer and boot the UI
    BOOL deauthenticateAfterConnection = NO;
    BOOL resumingSession = NO;
    if (self.applicationController.layerClient.authenticatedUserID) {
        if ([self resumeSession]) {
            resumingSession = YES;
            [self presentConversationsListViewController:NO];
        } else {
            deauthenticateAfterConnection = YES;
        }
    }
    
    // Connect Layer SDK
    [self.applicationController.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"Layer Client is connected");
            if (deauthenticateAfterConnection) {
                [self.applicationController.layerClient deauthenticateWithCompletion:nil];
            }
        } else {
            NSLog(@"Error connecting Layer: %@", error);
        }
        if (!resumingSession) {
            [self removeSplashView];
        }
    }];
    
    [self registerForRemoteNotifications:application];
    
    // Handle launching in response to push notification
    NSDictionary *remoteNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [self.applicationController.layerClient synchronizeWithRemoteNotification:remoteNotification completion:^(UIBackgroundFetchResult fetchResult, NSError *error) {
            if (fetchResult == UIBackgroundFetchResultFailed) {
                NSLog(@"Failed processing remote notification: %@", error);
            }
            
            // Try navigating once the synchronization completed
            LYRConversation *conversation = [self conversationFromRemoteNotification:remoteNotification];
            [self navigateToViewForConversation:conversation];
        }];
    }
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    self.localNotificationUtilities.shouldListenForChanges = NO;
    [self resumeSession];
    [self loadContacts];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self setApplicationBadgeNumber];
    if (self.applicationController.shouldDisplayLocalNotifications) {
        self.localNotificationUtilities.shouldListenForChanges = YES;
    }
}

#pragma mark - Setup

- (void)configureApplication:(UIApplication *)application forEnvironment:(LSEnvironment)environment
{
    self.environment = environment;
    
    // Configure Layer base URL
    NSString *configURLString = LSLayerConfigurationURL(self.environment);
    NSString *configKey = LSUserDefaultsLayerConfigurationURLKey;
    NSString *currentConfigURL = [[NSUserDefaults standardUserDefaults] objectForKey:configKey];
    if (![currentConfigURL isEqualToString:configURLString]) {
        [[NSUserDefaults standardUserDefaults] setObject:LSLayerConfigurationURL(self.environment) forKey:configKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    LSTestResetConfiguration();
    LYRSetLogLevelFromEnvironment();
    
    // Configure application controllers
    LSLayerClient *client = [LSLayerClient clientWithAppID:LSLayerAppID(self.environment)];
    
    // TODO: Change with subclass instead of interface class...
    self.applicationController = [LSApplicationController controllerWithBaseURL:LSRailsBaseURL()
                                                                    layerClient:client
                                                             persistenceManager:LSPersitenceManager()];
    
    self.localNotificationUtilities = [LSLocalNotificationUtilities initWithLayerClient:self.applicationController.layerClient];
    self.authenticationViewController.applicationController = self.applicationController;
}

- (BOOL)resumeSession
{
    LSSession *session = [self.applicationController.persistenceManager persistedSessionWithError:nil];
    if ([self.applicationController.APIManager resumeSession:session error:nil]) {
        return YES;
    }
    return NO;
}

- (void)setRootViewController
{
    self.authenticationViewController = [LSAuthenticationTableViewController new];
    self.authenticationViewController.applicationController = self.applicationController;
    self.authenticationViewController.delegate = self;

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = self.authenticationViewController;
    [self.window makeKeyAndVisible];
    
    [self addSplashView];
}

- (void)registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidAuthenticate:)
                                                 name:LSUserDidAuthenticateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]  addObserver:self
                                              selector:@selector(userDidAuthenticateWithLayer:)
                                                  name:LYRClientDidAuthenticateNotification
                                                object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidDeauthenticate:)
                                                 name:LSUserDidDeauthenticateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidTakeScreenshot:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification
                                               object:nil];
}

#pragma mark - Push Notifications

/**
 
 LAYER - In order to register for push notifications, your application must first declare the types of
 notifications it wishes to receive. This method handles doing so for both iOS 7 and iOS 8.
 
 */
- (void)registerForRemoteNotifications:(UIApplication *)application
{
    // Declaring that I want to recieve push!
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Application failed to register for remote notifications with error %@", error);
}

/**
 
 LAYER - When a user succesfully grants your application permission to receive push, the OS will call
 the following method. In your implementation of this method, your applicaiton should pass the 
 `deviceToken` parameter to the `LYRClient` object.
 
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    self.applicationController.deviceToken = deviceToken;
    NSError *error;
    BOOL success = [self.applicationController.layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
    if (success) {
        NSLog(@"Application did register for remote notifications");
    } else {
        NSLog(@"Error updating Layer device token for push:%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Updating Device Token Failed" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

/**
 
 LAYER - The following method gets called at 2 different times that interest a Layer powered application:
 
 1. When your application receives a push notification from Layer. Upon receiving a push, your application should 
 pass the `userInfo` dictionary to the `sychronizeWithRemoteNotification:completion:` method.
 
 2. When your application comes out of the background in response to a user opening the app from a push notification. 
 Your application can tell if it is coming our of the backroung by evaluating `application.applicationState`. If the 
 state is `UIApplicationSateInactive`, your application is coming out of the background and into the foreground.
 
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    BOOL userTappedRemoteNotification = application.applicationState == UIApplicationStateInactive;
    __block LYRConversation *conversation = [self conversationFromRemoteNotification:userInfo];
    if (userTappedRemoteNotification && conversation) {
        [self navigateToViewForConversation:conversation];
    }
    
    BOOL success = [self.applicationController.layerClient synchronizeWithRemoteNotification:userInfo completion:^(UIBackgroundFetchResult fetchResult, NSError *error) {
        if (fetchResult == UIBackgroundFetchResultFailed) {
            NSLog(@"Failed processing remote notification: %@", error);
        }
        // Try navigating once the synchronization completed
        if (userTappedRemoteNotification && !conversation) {
            conversation = [self conversationFromRemoteNotification:userInfo];
            [self navigateToViewForConversation:conversation];
        }
        // Increment badge count if a message
        [self setApplicationBadgeNumber];
        completionHandler(fetchResult);
    }];
    
    if (!success) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (LYRConversation *)conversationFromRemoteNotification:(NSDictionary *)remoteNotification
{
    // Fetch message object from LayerKit
    NSURL *conversationIdentifier = [NSURL URLWithString:[remoteNotification valueForKeyPath:@"layer.conversation_identifier"]];
    return [self.applicationController.layerClient conversationForIdentifier:conversationIdentifier];
}

- (void)navigateToViewForConversation:(LYRConversation *)conversation
{
    if (![NSThread isMainThread]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Attempted to navigate UI from non-main thread" userInfo:nil];
    }
    [self.conversationListViewController selectConversation:conversation];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (application.applicationState != UIApplicationStateInactive) return;

    LYRConversation *conversation;
    NSURL *objectURL = [NSURL URLWithString:notification.userInfo[LSNotificationIdentifierKey]];
    NSString *objectTypeString = notification.userInfo[LSNotificationClassTypeKey];
    if ([objectTypeString isEqualToString:LSNotificationClassTypeConversation]) {
        conversation = [self.applicationController.layerClient conversationForIdentifier:objectURL];
    } else {
        LYRMessage *message = [self.applicationController.layerClient messageForIdentifier:objectURL];
        conversation = message.conversation;
    }

    if (conversation) {
        [self navigateToViewForConversation:conversation];
    }
}

#pragma mark - SDK Initializers

- (void)initializeCrashlytics
{
    [Fabric with:@[CrashlyticsKit]];
    [Crashlytics setObjectValue:LSLayerConfigurationURL(self.environment) forKey:@"ConfigurationURL"];
    [Crashlytics setObjectValue:LSLayerAppID(self.environment) forKey:@"AppID"];
}

- (void)initializeHockeyApp
{
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"1681559bb4230a669d8b057adf8e4ae3"];
    [BITHockeyManager sharedHockeyManager].disableCrashManager = YES;
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
}

- (void)updateCrashlyticsWithUser:(LSUser *)authenticatedUser
{
    // Note: If authenticatedUser is nil, this will nil out everything which is what we want.
    [Crashlytics setUserName:authenticatedUser.fullName];
    [Crashlytics setUserEmail:authenticatedUser.email];
    [Crashlytics setUserIdentifier:authenticatedUser.userID];
}

#pragma mark - Authentication Notification Handlers

- (void)userDidAuthenticateWithLayer:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self userDidAuthenticateWithLayer:notification];
        });
        return;
    }
    [self presentConversationsListViewController:YES];
}

- (void)userDidAuthenticate:(NSNotification *)notification
{
    NSError *error;
    LSSession *session = self.applicationController.APIManager.authenticatedSession;
    BOOL success = [self.applicationController.persistenceManager persistSession:session error:&error];
    if (success) {
        NSLog(@"Persisted authenticated user session: %@", session);
    } else {
        NSLog(@"Failed persisting authenticated user: %@. Error: %@", session, error);
        LSAlertWithError(error);
    }
    
    [self updateCrashlyticsWithUser:session.user];
    [self loadContacts];
}

- (void)userDidDeauthenticate:(NSNotification *)notification
{
    NSError *error;
    BOOL success = [self.applicationController.persistenceManager persistSession:nil error:&error];
    
    // Clear out all Crashlytics user information.
    [self updateCrashlyticsWithUser:nil];
    
    if (success) {
        NSLog(@"Cleared persisted user session");
    } else {
        NSLog(@"Failed clearing persistent user session: %@", error);
        LSAlertWithError(error);
    }
    
    [self.authenticationViewController dismissViewControllerAnimated:YES completion:^{
        self.conversationListViewController = nil;
    }];
}

#pragma mark - Contacts

- (void)loadContacts
{
    [self.applicationController.APIManager loadContactsWithCompletion:^(NSSet *contacts, NSError *error) {
        if (error) {
            LSAlertWithError(error);
            return;
        }
        NSError *persistenceError;
        BOOL success = [self.applicationController.persistenceManager persistUsers:contacts error:&persistenceError];
        if (!success) {
            LSAlertWithError(persistenceError);
        }
    }];
}

#pragma mark - Conversations

- (void)presentConversationsListViewController:(BOOL)animated
{
    if (!LSIsRunningTests()) {
        if (self.conversationListViewController) return;

        self.conversationListViewController = [LSUIConversationListViewController conversationListViewControllerWithLayerClient:self.applicationController.layerClient];
        self.conversationListViewController.applicationController = self.applicationController;
        self.conversationListViewController.displaysConversationImage = self.displaysConversationImage;
        self.conversationListViewController.cellClass = self.cellClass;
        self.conversationListViewController.rowHeight = self.rowHeight;
        self.conversationListViewController.allowsEditing = self.allowsEditing;
        self.conversationListViewController.shouldDisplaySettingsItem = self.displaysSettingsButton;
        
        UINavigationController *authenticatedNavigationController = [[UINavigationController alloc] initWithRootViewController:self.conversationListViewController];
        [self.authenticationViewController presentViewController:authenticatedNavigationController animated:YES completion:^{
            [self.authenticationViewController resetState];
            [self removeSplashView];
        }];
    } else {
        [self removeSplashView];
    }
}

#pragma mark - Splash View

- (void)addSplashView
{
    if (!self.splashView) {
        self.splashView = [[LSSplashView alloc] initWithFrame:self.window.bounds];
    }
    [self.window addSubview:self.splashView];
}

- (void)removeSplashView
{
    [UIView animateWithDuration:0.5 animations:^{
        self.splashView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.splashView removeFromSuperview];
        self.splashView = nil;
    }];
}

#pragma mark - UI Config

- (void)configureGlobalUserInterfaceAttributes
{
    [[UINavigationBar appearance] setTintColor:LYRUIBlueColor()];
    [[UINavigationBar appearance] setBarTintColor:LYRUILightGrayColor()];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName: LYRUIBoldFont(18)}];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:@{NSFontAttributeName : LYRUIMediumFont(16)} forState:UIControlStateNormal];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:LYRUIBlueColor()];
}

#pragma mark - Bug Reporting

- (void)userDidTakeScreenshot:(NSNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Report Issue?"
                                                        message:@"Would you like to report a bug with the sample app?"
                                                       delegate:self
                                              cancelButtonTitle:@"Not Now"
                                              otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)presentMailComposer
{
    LYRUILastPhotoTaken(^(UIImage *image, NSError *error) {
        if (error) {
            return;
        } else {
            NSString *emailSubject = @"New iOS Sample App Bug!";
            NSString *emailBody = @"Please enter your bug description below";
            
            self.mailComposeViewController = [MFMailComposeViewController new];
            self.mailComposeViewController.mailComposeDelegate = self;
            [self.mailComposeViewController setSubject:emailSubject];
            [self.mailComposeViewController setMessageBody:emailBody isHTML:NO];
            [self.mailComposeViewController setToRecipients:@[@"kevin@layer.com", @"jira@layer.com"]];
            [self.mailComposeViewController addAttachmentData:UIImageJPEGRepresentation(image, 0.5) mimeType:@"image/png" fileName:@"screenshot.png"];
            
            UIViewController *controller = self.window.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:self.mailComposeViewController animated:YES completion:nil];
        }
    });
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self presentMailComposer];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSaved:
            [SVProgressHUD showSuccessWithStatus:@"Email Saved"];
            break;
        case MFMailComposeResultSent:
            [SVProgressHUD showSuccessWithStatus:@"Email Sent! Now go tell Kevin or Ben to fix it!"];
            break;
        case MFMailComposeResultFailed:
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Email Failed to Send. Error: %@", error]];
            break;
        default:
            break;
    }
    [self.mailComposeViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - LSAuthenticationTableViewControllerDelegate

- (void)authenticationTableViewController:(LSAuthenticationTableViewController *)authenticationTabelViewController didSelectEnvironment:(LSEnvironment)environment
{
    if (self.applicationController.layerClient.isConnected) {
        [self.applicationController.layerClient disconnect];
    }
    [self configureApplication:[UIApplication sharedApplication] forEnvironment:environment];
}

#pragma mark - Application Badge Setter 

- (void)setApplicationBadgeNumber
{
    NSUInteger countOfUnreadMessages = [self.applicationController.layerClient countOfUnreadMessages];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:countOfUnreadMessages];
}

@end
