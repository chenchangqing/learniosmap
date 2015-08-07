//
//  ViewController.swift
//  example01
//
//  Created by green on 15/8/7.
//  Copyright (c) 2015年 com.chenchangqing. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController,MKMapViewDelegate,UIActionSheetDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    private let sourceName      = "高安市新宇小区"
    private let destinationName = "高安中学"
    
    private let geocoder        = CLGeocoder()                          // 反编码类
    private let request         = MKDirectionsRequest()                 // 导航请求
    private let transportType   = MKDirectionsTransportType.Automobile  // 当前导航类型
    
    private var sourceAnnotation        : MKPointAnnotation!    // 出发地标注
    private var destinationAnnotation   : MKPointAnnotation!    // 目的地标注
    
    private var sourceItem              : MKMapItem!            // 出发地节点
    private var destinationItem         : MKMapItem!            // 目的地节点
    private var mapLauncher             : ASMapLauncher!        // 打开地图的工具类
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapLauncher                     = ASMapLauncher()
        mapView.delegate                = self                                    // 地图代理
        request.transportType           = transportType                           // 路径类型汽车
        request.requestsAlternateRoutes = false                                   // 设置是否搜索多条线路
        
        // 反编码出CLPlacemark对象
        geocodeAddress(sourceName, destinationName: destinationName) { (sourceMark, destinationMark) -> Void in
            
            // 增加标注
            self.addAnnotions(sourceMark, destinationMark: destinationMark)
            
            // 划线
            self.drawGuideLine(sourceMark, destinationMark: destinationMark)
        }
    }
    
    // MARK: -
    
    /**
     * 将出发地、目的地反编码
     * @param sourceName 出发地名称
     * @param destinationName 目的地名称
     * @param callback 回调函数
     *
     * @return 
     */
    private func geocodeAddress(sourceName:String, destinationName:String, callback:(sourceMark:CLPlacemark,destinationMark:CLPlacemark) -> Void) {
        
        geocoder.geocodeAddressString(sourceName, completionHandler: { (sourcemarks, error) -> Void in
            
            if let error = error {
                
                println("出发地反编码失败")
                return
            }
            
            if sourcemarks?.count == 0 {
                
                println("没有查询到出发地")
                return
            }
            
            self.geocoder.geocodeAddressString(destinationName, completionHandler: { (destinationmarks, error) -> Void in
                
                if let error = error {
                    
                    println("目的地反编码失败")
                    return
                }
                
                if destinationmarks?.count == 0 {
                    
                    println("没有查询到目的地")
                    return
                }
                
                // 地理位置信息
                let sourcemark      = sourcemarks[0] as! CLPlacemark
                let destinationmark = destinationmarks[0] as! CLPlacemark
                
                // 地图区域
                let currentLocationSpan     = MKCoordinateSpanMake(0.05, 0.05)
                let currentRegion           = MKCoordinateRegionMake(destinationmark.location.coordinate, currentLocationSpan)
                self.mapView.setRegion(currentRegion, animated: false)
                
                // 回调
                callback(sourceMark: sourcemark, destinationMark: destinationmark)
            })
        })
    }
    
    /**
     * 根据地理信息增加地图标注
     * @param sourceMark 出发地位置信息
     * @param destinationMark 目的地位置信息
     * 
     * @return
     */
    private func addAnnotions(sourceMark:CLPlacemark,destinationMark:CLPlacemark) {
        
        sourceAnnotation            = MKPointAnnotation()
        sourceAnnotation.title      = sourceName
        sourceAnnotation.subtitle   = sourceMark.name
        sourceAnnotation.coordinate = sourceMark.location.coordinate
        mapView.addAnnotation(sourceAnnotation)
        
        destinationAnnotation               = MKPointAnnotation()
        destinationAnnotation.title         = destinationName
        destinationAnnotation.subtitle      = destinationMark.name
        destinationAnnotation.coordinate    = destinationMark.location.coordinate
        mapView.addAnnotation(destinationAnnotation)
        
    }
    
    /**
     * 根据地理信息规划路线
     * @param sourceMark 出发地位置信息
     * @param destinationMark 目的地位置信息
     *
     * @return
     */
    private func drawGuideLine(sourceMark:CLPlacemark,destinationMark:CLPlacemark) {
        
        // 开始地点节点
        let sourcemkmark    = MKPlacemark(placemark: sourceMark)
        sourceItem          = MKMapItem(placemark: sourcemkmark)
        request.setSource(sourceItem)
        
        // 结束地点节点
        let destinationmkmark   = MKPlacemark(placemark: destinationMark)
        destinationItem         = MKMapItem(placemark: destinationmkmark)
        request.setDestination(destinationItem)
        
        // 从apple服务器获取数据的连接类
        let directions = MKDirections(request: request)
        
        // 开始计算路线信息
        directions.calculateDirectionsWithCompletionHandler { (response, error) -> Void in
            
            if let error = error {
                
                println("计算路线失败")
                return
            }
            
            let routes = response.routes
            
            for route in routes {
                
                let mkRoute     = route as! MKRoute
                let polyline    = mkRoute.polyline
                self.mapView.addOverlay(polyline)
            }
        }
    }

    // MARK: -
    
    /**
     * 打开苹果地图或谷歌地图
     */
    @IBAction func navigationClick(sender: UIButton) {
        
//        lanunchTypeOne()
        lanunchTypeTwo()
    }
    
    private func lanunchTypeOne() {
        
        // 设置开始、结束节点
        let mapItems = [sourceItem,destinationItem]
        
        // 设置导航模式
        let dic: [NSObject : AnyObject] = [
            MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey:true
        ]
        
        // 打开苹果地图开始导航
        MKMapItem.openMapsWithItems(mapItems, launchOptions: dic)
    }
    
    private func lanunchTypeTwo() {
        
        // 使用ActionSheet
        let actionSheet = UIActionSheet(title: "请选择", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
        
        for mapApp in mapLauncher.getMapApps() {
            
            actionSheet.addButtonWithTitle(mapApp as! String)
        }
        
        actionSheet.addButtonWithTitle("取消")
        actionSheet.cancelButtonIndex = mapLauncher.getMapApps().count
        actionSheet.showInView(self.view)
        
    }
    
    // MARK: - UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
        if buttonIndex == actionSheet.numberOfButtons - 1 {
            
            return
        }
        
        let mapApp       = mapLauncher.getMapApps()[buttonIndex] as! String
        let fromMapPoint = ASMapPoint(location: sourceItem.placemark.location, name: "", address: "")
        let toMapPoint   = ASMapPoint(location: destinationItem.placemark.location, name: "", address: "")
        
        mapLauncher.launchMapApp(ASMapApp(rawValue: mapApp)!, fromDirections: fromMapPoint, toDirection: toMapPoint)
    }
    

    // MARK: - MKMapViewDelegate
    
    /*
     * 渲染标注
     */
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let identifierStr       = "pinAnnotationView"
        var pinAnnotationView   = mapView.dequeueReusableAnnotationViewWithIdentifier(identifierStr) as? MKPinAnnotationView
        
        if pinAnnotationView == nil {
            
            pinAnnotationView                   = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifierStr)
            // 显示标注提示
            pinAnnotationView!.canShowCallout   = true
        }
        
        // 大头针颜色
        let annotation = annotation as! MKPointAnnotation
        if annotation == sourceAnnotation {
            
            pinAnnotationView!.pinColor = MKPinAnnotationColor.Green
        }
        
        if annotation == destinationAnnotation {
            
            pinAnnotationView!.pinColor = MKPinAnnotationColor.Red
        }
        return  pinAnnotationView
    }
    
    /*
     * 渲染路线
     */
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        let render          = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        render.lineWidth    = 5
        render.strokeColor  = UIColor.blueColor()
        return render
    }
}

