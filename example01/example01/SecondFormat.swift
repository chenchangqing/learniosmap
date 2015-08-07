//
//  SecondFormat.swift
//  example01
//
//  Created by green on 15/8/7.
//  Copyright (c) 2015年 com.chenchangqing. All rights reserved.
//

import UIKit

class SecondFormat: NSObject {
    
    // 将秒数格式化
    class func formatTime(timeCGFloat: CGFloat) -> String {
        
        let time = Int(timeCGFloat)
        var result = "00:00:00"
        
        if time < 60 {
            
            if time < 10 {
                
                result = "00:00:0\(time)"
            }
            
            if time >= 10 {
                
                result = "00:00:\(time)"
            }
        }
        
        if time == 60 {
            
            result = "00:01:00"
        }
        
        if time > 60 {
            
            if time < 3600 {
                
                var minutes = time/60
                var secs = time%60
                
                if minutes < 10 && secs < 10 {
                    
                    result = "00:0\(minutes):0\(secs)"
                }
                if minutes < 10 && secs >= 10 {
                    
                    result = "00:0\(minutes):\(secs)"
                }
                if minutes >= 10 && secs < 10 {
                    
                    result = "00:\(minutes):0\(secs)"
                }
                if minutes >= 10 && secs >= 10 {
                    
                    result = "00:\(minutes):\(secs)"
                }
            }
            
            if time == 3600 {
                
                result = "01:00:00"
            }
            
            if time > 3600 {
                
                var hours = time/3600
                var tempsecs = time%3600
                var minutes = tempsecs/60
                var secs = tempsecs%60
                
                var hoursV = "\(hours)"
                var minutesV = "\(minutes)"
                var secsV = "\(secs)"
                
                if hours < 10 {
                    
                    hoursV = "0\(hours)"
                }
                
                if minutes < 10 {
                    
                    minutesV = "0\(minutes)"
                }
                
                if secs < 10 {
                    
                    secsV = "0\(secs)"
                }
                
                result = hoursV + ":" + minutesV + ":" + secsV
            }
        }
        
        return result
    }
}
