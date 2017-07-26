
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit
import CRToast

extension CRToast {
    
    // Shows a toast in red
    static func toast(message: String, completion: @escaping(()->())) {
        
        let options: [String:Any] = [kCRToastTextKey :                  message,
                                     kCRToastTextAlignmentKey :         NSTextAlignment.center,
                                     kCRToastBackgroundColorKey :       UIColor.red,
                                     kCRToastAnimationInTypeKey :       CRToastAnimationType.gravity,
                                     kCRToastAnimationOutTypeKey :      CRToastAnimationType.gravity,
                                     kCRToastAnimationInDirectionKey :  CRToastAnimationDirection.bottom,
                                     kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.top]
        
        CRToastManager.showNotification(options: options, completionBlock: completion)
    }
}
