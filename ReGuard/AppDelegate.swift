import UIKit
import AWSCore
import Amplify
import AmplifyPlugins

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let authSessManager = AuthSessionManager.shared
    let networkManager = NetworkManager.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:7ebe7028-f342-4a23-a977-39db064e1ba3")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        renderRoot()
        return true
    }
    
    func renderRoot() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var rootController: UIViewController? = nil
        
        switch authSessManager.authState {
        case .session(let user):
            let userId = user.userId
            guard let deviceId = UIDevice.current.identifierForVendor else {
                fatalError("Unable to get a device ID!")
            }
            networkManager.getDeviceForUser(userId: userId, deviceId: deviceId.uuidString) { deviceInfo in
                DispatchQueue.main.async {
                    if let deviceInfo = deviceInfo {
                        if let device = deviceInfo.device {
                            rootController = mainStoryboard.instantiateViewController(withIdentifier: "DetectionViewController") as! DetectionViewController
                            print("Showing detection screen")
                        } else {
                            rootController = mainStoryboard.instantiateViewController(withIdentifier: "ConfigureGuardianViewController") as! ConfigureGuardianViewController
                            print("Showing configure screen")
                        }
                    } else {
                        fatalError("Unable to retrieve device registration info")
                    }
                    self.window?.rootViewController = rootController
                }
            }
        default:
            rootController = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
            let navigationController = UINavigationController(rootViewController: rootController!)
            print("Showing login screen")
            self.window?.rootViewController = navigationController
        }
        
        window?.makeKeyAndVisible()
    }
}
