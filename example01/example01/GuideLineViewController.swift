//
//  GuideLineViewController.swift
//  example01
//
//  Created by green on 15/8/7.
//  Copyright (c) 2015年 com.chenchangqing. All rights reserved.
//

import UIKit
import MapKit

class GuideLineViewController: UIViewController,MKMapViewDelegate,UIActionSheetDelegate,CLLocationManagerDelegate {
    
    @IBOutlet weak var lineDetailL  : UILabel!
    @IBOutlet weak var mapView      : MKMapView!
    
    private let request         = MKDirectionsRequest()                 // 导航请求
    private var transportType   : MKDirectionsTransportType?   // 当前导航类型
    {
        willSet {
            
            if let newValue = newValue {
                
                // 设置新的导航类型
                request.transportType = newValue
                
                // 删除已有的路线
                for mkRoute in mkRouteArray {
                    
                    mapView.removeOverlay(mkRoute.polyline)
                }
                
                // 重新绘制路线
                if let destinationPlaceMark=destinationPlaceMark {
                    
                    self.drawGuideLine(destinationPlaceMark)
                }
            }
        }
    }
    
    var destinationCoordinate       : CLLocationCoordinate2D?   // 目标经纬度
    {
        willSet{
            
            if let newValue=newValue {
                
                if !CLLocationCoordinate2DIsValid(newValue) {
                    
                    return
                }
                
                // 地图区域
                let currentLocationSpan     = MKCoordinateSpanMake(0.05, 0.05)
                let currentRegion           = MKCoordinateRegionMake(newValue, currentLocationSpan)
                self.mapView.setRegion(currentRegion, animated: false)
                
                // 经纬度转地址
                geocoder.reverseGeocodeLocation(CLLocation(latitude: newValue.latitude, longitude: newValue.longitude), completionHandler: { (array, error) -> Void in
                    
                    if let error=error {
                        
                        println("目的地定位失败")
                        return
                    }
                    
                    if array.count > 0 {
                        
                        self.destinationPlaceMark                   = array[0] as? CLPlacemark
                        self.transportType                          = MKDirectionsTransportType.Automobile
                        
                        // 增加出发地标注
                        self.destinationAnnotation                  = MKPointAnnotation()
                        self.destinationAnnotation!.title           = self.destinationPlaceMark!.name
                        self.destinationAnnotation!.coordinate      = newValue
                        self.mapView.addAnnotation(self.destinationAnnotation!)
                    }
                })
            } else {
                
                if let destinationAnnotation=destinationAnnotation {
                    
                    self.mapView.removeAnnotation(destinationAnnotation)
                }
                
                self.destinationPlaceMark    = nil
                self.destinationAnnotation   = nil
            }
            
        }
    }
    
    private var destinationAnnotation   : MKPointAnnotation?    // 目的地标注
    private var destinationPlaceMark    : CLPlacemark?          // 目的地信息
    
    private var mapLauncher             : ASMapLauncher!        // 打开地图的工具类
    private var mkRouteArray            = [MKRoute]()           // 路线数组
    private let geocoder                = CLGeocoder()          // 编码反编码
    
    // 定位服务
    lazy var locationManager : CLLocationManager = {
        
        let locationManager             = CLLocationManager()
        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter  = 10
        
        if UIDevice.currentDevice().systemVersion >= "8.0.0" {
            
            locationManager.requestWhenInUseAuthorization()
        }
        return locationManager
    }()
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapLauncher                     = ASMapLauncher()
        mapView.delegate                = self                                    // 地图代理
        request.requestsAlternateRoutes = false                                   // 设置是否搜索多条线路
        mapView.showsUserLocation       = true
        
        // 开始定位
        startUpdatingL()
        
        // 触发增加标注、划线
        self.destinationCoordinate      = CLLocationCoordinate2D(latitude:31.216739784766 , longitude: 121.587560439984)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // MARK: -
    
    /**
     * 开始定位
     */
    func startUpdatingL() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                
                let alertVC = UIAlertController(title: "提示", message: "需要开启定位服务,请到设置->隐私,打开定位服务", preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction(title: "好", style: UIAlertActionStyle.Default, handler: nil)
                alertVC.addAction(ok)
                self.presentViewController(alertVC, animated: true, completion: nil)
            } else {
                
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    /**
     * 根据地理信息规划路线
     * @param sourceMark 出发地位置信息
     * @param destinationMark 目的地位置信息
     *
     * @return
     */
    private func drawGuideLine(destinationMark:CLPlacemark) {
        
        // 开始地点节点
        request.setSource(MKMapItem.mapItemForCurrentLocation())
        
        // 结束地点节点
        let destinationmkmark   = MKPlacemark(placemark: destinationMark)
        let destinationItem     = MKMapItem(placemark: destinationmkmark)
        request.setDestination(destinationItem)
        
        // 从apple服务器获取数据的连接类
        let directions = MKDirections(request: request)
        
        // 开始计算路线信息
        directions.calculateDirectionsWithCompletionHandler { (response, error) -> Void in
            
            if let error = error {
                
                println("计算路线失败")
                return
            }
            
            self.mkRouteArray = response.routes as! [MKRoute]
            
            if self.mkRouteArray.count != 1 {
                
                println("查询出\(self.mkRouteArray.count)条路线")
                return
            }
            
            for mkRoute in self.mkRouteArray {
                
                self.mapView.addOverlay(mkRoute.polyline)
                
                let cgTravelTime  = CGFloat(mkRoute.expectedTravelTime)
                let caculatedTime = SecondFormat.formatTime(cgTravelTime)
                self.lineDetailL.text = "\(caculatedTime),\(mkRoute.distance)米"
            }
        }
    }

    // MARK: -
    
    /**
     * 打开苹果地图或谷歌地图
     */
    @IBAction func navigationClick(sender: UIButton) {
        
        if let sourceCoordinate=mapView.userLocation {
            if let destinationCoordinate=destinationCoordinate {
                
                // 使用ActionSheet
                let actionSheet = UIActionSheet(title: "请选择", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
                
                for mapApp in mapLauncher.getMapApps() {
                    
                    actionSheet.addButtonWithTitle(mapApp as! String)
                }
                
                actionSheet.addButtonWithTitle("取消")
                actionSheet.cancelButtonIndex = mapLauncher.getMapApps().count
                actionSheet.showInView(self.view)
            }
        }
    }
    
    // MARK: - UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
        if buttonIndex == actionSheet.numberOfButtons - 1 {
            
            return
        }
        
        let mapApp       = mapLauncher.getMapApps()[buttonIndex] as! String
        let fromMapPoint = ASMapPoint(location: mapView.userLocation.location , name: "", address: "")
        let toMapPoint   = ASMapPoint(location: CLLocation(latitude: destinationCoordinate!.latitude, longitude: destinationCoordinate!.longitude), name: "", address: "")
        
        mapLauncher.launchMapApp(ASMapApp(rawValue: mapApp)!, fromDirections: fromMapPoint, toDirection: toMapPoint)
    }
    
    // MARK: -
    
    /**
     * 根据导航类型重新绘制路线
     */
    @IBAction func changeGuideType(sender: UISegmentedControl) {
        
        // println(sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!)
        
        // 自驾
        if sender.selectedSegmentIndex == 0 {
            
            self.transportType = MKDirectionsTransportType.Automobile
        }
        
        // 步行
        if sender.selectedSegmentIndex == 1 {
            
            self.transportType = MKDirectionsTransportType.Walking
        }
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
        if annotation is MKUserLocation  {
            
            pinAnnotationView!.pinColor = MKPinAnnotationColor.Green
        }
        
        if annotation is MKPointAnnotation {
            
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
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        
    }
}

