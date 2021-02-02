import UIKit
import AWSCore
import Amplify
import AmplifyPlugins

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var authSessManager: AuthSessionManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureAmplify()
        authSessManager = AuthSessionManager()
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:7ebe7028-f342-4a23-a977-39db064e1ba3")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        renderRoot()
        return true
    }
    
    func renderRoot() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var rootController: UIViewController
        
        switch authSessManager!.authState {
        case .session(let user):
            rootController = mainStoryboard.instantiateViewController(withIdentifier: "DetectionViewController") as! DetectionViewController
            print("Showing detection screen")
            self.window?.rootViewController = rootController
        default:
            rootController = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
            (rootController as! LoginViewController).authSessionManager = authSessManager
            let navigationController = UINavigationController(rootViewController: rootController)
            print("Showing login screen")
            self.window?.rootViewController = navigationController
        }
        
        window?.makeKeyAndVisible()
    }
    
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Amplify configured successfully")
        } catch {
            print("Unable to configure amplify: \(error)")
        }
    }
}
