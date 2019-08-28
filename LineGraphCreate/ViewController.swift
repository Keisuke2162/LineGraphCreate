//
//  ViewController.swift
//  LineGraphCreate
//
//  Created by Kei on 2019/08/24.
//  Copyright © 2019 Keisuke Ueda. All rights reserved.
//


import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //折れ線グラフ
        drawLineGraph()
        
        //棒グラフ
        drawBarGraph()
    }
    
    /******************************************************
     グラフ描画には　UIViewのdrawメソッド と　UIBezierPath() を使用する。
     
     座標(from)と座標(to)の間に線を引く処理を繰り返してグラフを作成する
     
     グラフに載せたいデータの入り口はstroke1,stroke2（載せたいデータはここに持ってくる）
     ******************************************************/
    
    func drawLineGraph() {
        //グラフデータ（二つの折れ線グラフを描画する）
        let stroke1 = LineStroke(graphPoints: [1.0, 3.5, 1.3, 4.45, 9.2, 10, 3])
        let stroke2 = LineStroke(graphPoints: [3, nil, 6, 4, 4])
        
        stroke1.color = UIColor.cyan
        stroke2.color = UIColor.magenta
        
        //グラフのグリッド
        let graphFrame = LineStrokeGraphFrame(strokes: [stroke1, stroke2])
        
        let lineGraphView = UIView(frame: CGRect(x: 0, y: view.frame.height / 10 * 2, width: view.frame.width, height: 200))
        lineGraphView.backgroundColor = UIColor.gray
        lineGraphView.addSubview(graphFrame)
        
        view.addSubview(lineGraphView)
    }
    
    func drawBarGraph() {
        let bars = BarStroke(graphPoints: [nil, 1, 3, 1, 4, 9, 12, 4])
        bars.color = UIColor.green
        
        let barFrame = LineStrokeGraphFrame(strokes: [bars])
        
        let barGraphView = UIView(frame: CGRect(x: 0, y: view.frame.height / 10 * 5, width: view.frame.width, height: 200))
        barGraphView.backgroundColor = UIColor.gray
        barGraphView.addSubview(barFrame)
        
        view.addSubview(barGraphView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

protocol GraphObject {
    var view: UIView { get }
}

//グラフの外枠と縦線？（グラフの基準点みたいなの）を描画する
//「描画する」だけで、どこからどこまで引くかはGraphFrame、GraphStrokeで定義する

extension GraphObject {
    var view: UIView {
        return self as! UIView
    }
    
    func drawLine(from: CGPoint, to: CGPoint) {
        let linePath = UIBezierPath()
        
        linePath.move(to: from)
        linePath.addLine(to: to)
        
        linePath.lineWidth = 1
        
        let color = UIColor.white
        color.setStroke()
        linePath.stroke()
        linePath.close()
    }
}

protocol GraphFrame: GraphObject {
    var strokes: [GraphStroke] { get }
}

extension GraphFrame {
    // 保持しているstrokesの中で最大値
    var yAxisMax: CGFloat {
        //stroke1,stroke2のうち数値は一番大きいものに合わせてグラフの高さを定義する
        return strokes.map{ $0.graphPoints }.flatMap{ $0 }.compactMap{ $0 }.max()!
    }
    
    // 保持しているstrokesの中でいちばん長い配列の長さ
    var xAxisPointsCount: Int {
        //stroke1,stroke2のうち要素数が多い方の要素数
        return strokes.map{ $0.graphPoints.count }.max()!
    }
    
    // X軸の点と点の幅
    var xAxisMargin: CGFloat {
        return view.frame.width/CGFloat(xAxisPointsCount)
    }
}

class LineStrokeGraphFrame: UIView, GraphFrame {
    var strokes = [GraphStroke]()
    
    convenience init(strokes: [GraphStroke]) {
        self.init()
        self.strokes = strokes
    }
    
    override func didMoveToSuperview() {
        if self.superview == nil { return }
        self.frame.size = self.superview!.frame.size
        self.view.backgroundColor = UIColor.clear
        
        strokeLines()
    }
    
    func strokeLines() {
        for stroke in strokes {
            self.addSubview(stroke as! UIView)
        }
    }
    
    override func draw(_ rect: CGRect) {
        drawTopLine()
        drawBottomLine()
        drawVerticalLines()
    }
    
    func drawTopLine() {
        self.drawLine(
            from: CGPoint(x: 0, y: frame.height),
            to: CGPoint(x: frame.width, y: frame.height)
        )
    }
    
    func drawBottomLine() {
        self.drawLine(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: frame.width, y: 0)
        )
    }
    
    func drawVerticalLines() {
        for i in 1..<xAxisPointsCount {
            let x = xAxisMargin*CGFloat(i)
            self.drawLine(
                from: CGPoint(x: x, y: 0),
                to: CGPoint(x: x, y: frame.height)
            )
        }
    }
}


protocol GraphStroke: GraphObject {
    var graphPoints: [CGFloat?] { get }
}

//グラフの枠組みを定義
extension GraphStroke {
    var graphFrame: GraphFrame? {
        return ((self as! UIView).superview as? GraphFrame)
    }
    
    var graphHeight: CGFloat {
        return view.frame.height
    }
    
    var xAxisMargin: CGFloat {
        return graphFrame!.xAxisMargin
    }
    
    var yAxisMax: CGFloat {
        return graphFrame!.yAxisMax
    }
    
    // indexからX座標を取る
    func getXPoint(index: Int) -> CGFloat {
        return CGFloat(index) * xAxisMargin
    }
    
    // 値からY座標を取る
    func getYPoint(yOrigin: CGFloat) -> CGFloat {
        let y: CGFloat = yOrigin/yAxisMax * graphHeight
        return graphHeight - y
    }
}

//折れ線グラフ描画クラス
class LineStroke: UIView, GraphStroke {
    var graphPoints = [CGFloat?]()
    var color = UIColor.white
    
    convenience init(graphPoints: [CGFloat?]) {
        self.init()
        self.graphPoints = graphPoints
    }
    
    
    override func didMoveToSuperview() {
        if self.graphFrame == nil { return }
        self.frame.size = self.graphFrame!.view.frame.size
        self.view.backgroundColor = UIColor.clear
    }
    
    
    override func draw(_ rect: CGRect) {
        let graphPath = UIBezierPath()
        
        graphPath.move(
            to: CGPoint(x: getXPoint(index: 0), y: getYPoint(yOrigin: graphPoints[0] ?? 0))
        )
        
        for graphPoint in graphPoints.enumerated() {
            if graphPoint.element == nil { continue }
            let nextPoint = CGPoint(x: getXPoint(index: Int(graphPoint.offset)),
                                    y: getYPoint(yOrigin: graphPoint.element!))
            graphPath.addLine(to: nextPoint)
        }
        
        graphPath.lineWidth = 5.0
        color.setStroke()
        graphPath.stroke()
        graphPath.close()
    }
}


//棒グラフ描画クラス
class BarStroke: UIView, GraphStroke {
    var graphPoints = [CGFloat?]()
    var color = UIColor.white
    
    convenience init(graphPoints: [CGFloat?]) {
        self.init()
        self.graphPoints = graphPoints
    }
    
    override func didMoveToSuperview() {
        if self.graphFrame == nil { return }
        self.frame.size = self.graphFrame!.view.frame.size
        self.view.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        for graphPoint in graphPoints.enumerated() {
            let graphPath = UIBezierPath()
            
            let xPoint = getXPoint(index: Int(graphPoint.offset))
            graphPath.move(
                to: CGPoint(x: xPoint, y: getYPoint(yOrigin: 0))
            )
            
            if graphPoint.element == nil { continue }
            let nextPoint = CGPoint(x: xPoint, y: getYPoint(yOrigin: graphPoint.element!))
            graphPath.addLine(to: nextPoint)
            
            graphPath.lineWidth = 30
            color.setStroke()
            graphPath.stroke()
            graphPath.close()
        }
    }
}
