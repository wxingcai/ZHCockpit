//
//  Extension.swift
//  ScreenShield
//
//  Created by wangxc on 2023/11/21.
//

import UIKit

extension UIDevice {
    
    class func safeAreaBottom() -> CGFloat {
        var bottom:CGFloat = 0
        bottom = UIApplication.shared.windows[0].safeAreaInsets.bottom
        return bottom
    }
    
    class func safeAreaTop() -> CGFloat {
        var top: CGFloat = 0
        let keyWindow = UIApplication.shared.windows.first
        if keyWindow != nil {
            top = keyWindow?.safeAreaInsets.top ?? 0
        }
        return top
    }
}

extension UIColor {
    
    class func colorWithRgbAlpha(_ r:CGFloat, _ g:CGFloat, _ b:CGFloat, alpha:CGFloat=1.0) -> UIColor {
        return self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: alpha)
    }
    
    // 字符串转 UIColor
    class func hexStringToColor(hex: String, alpha: CGFloat) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.count < 6 {
            return UIColor.white
        }
        // 判断前缀
        if cString.hasPrefix("0x") {
            cString.removeFirst(2)
        }
        if cString.hasPrefix("0X") {
            cString.removeFirst(2)
        }
        if cString.hasPrefix("#") {
            cString.removeFirst(1)
        }
        if cString.count != 6 {
            return UIColor.white
        }
        
        let rString = (cString as NSString).substring(to: 2)
        let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        _ = Scanner(string: rString).scanHexInt64(&r)
        _ = Scanner(string: gString).scanHexInt64(&g)
        _ = Scanner(string: bString).scanHexInt64(&b)
        return UIColor.colorWithRgbAlpha(CGFloat(r), CGFloat(g), CGFloat(b), alpha: alpha)
    }        
}
