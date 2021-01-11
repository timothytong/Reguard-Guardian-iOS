import UIKit
import AWSCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
       identityPoolId:"us-east-1:7ebe7028-f342-4a23-a977-39db064e1ba3")

    let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)

    AWSServiceManager.default().defaultServiceConfiguration = configuration
    return true
  }
}
