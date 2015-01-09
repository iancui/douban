import UIKit
import MediaPlayer
import QuartzCore

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HttpProtocol,ChannelProtocol{

    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var tv: UITableView!
    @IBOutlet var btnPlay: UIImageView!
    @IBOutlet var tap: UITapGestureRecognizer! = nil
    
    var tableData:NSArray = NSArray()
    var channelData:NSArray = NSArray()
    var imageCache = Dictionary<String,UIImage>()
    // 播放器
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    
    var timer:NSTimer?
    @IBAction func onTap(sender: UITapGestureRecognizer) {
        if sender.view == btnPlay {
            btnPlay.hidden = true
            audioPlayer.play()
            btnPlay.removeGestureRecognizer(tap)
            iv.addGestureRecognizer(tap)
            println("btnPlay clicked")
        }else if sender.view == iv {
            btnPlay.hidden = false
            audioPlayer.pause()
            btnPlay.addGestureRecognizer(tap)
            iv.removeGestureRecognizer(tap)
        }
        println("clicked")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        eHttp.onSearch("http://douban.fm/j/mine/playlist?channel=0")
        progressView.progress = 0.0
        iv.addGestureRecognizer(tap)
    }

    @IBOutlet weak var playTime: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var eHttp:HttpController = HttpController()
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "song")
        
        let rowData:NSDictionary = self.tableData[indexPath.row] as NSDictionary
        
        
        cell.textLabel?.text = rowData["title"] as? String

        cell.detailTextLabel?.text = rowData["artist"] as? String

        cell.imageView?.image = UIImage(named: "detail.png")
        let url = rowData["picture"] as String
        let image = self.imageCache[url]
        
        if !(image != nil) {
            let imgURL:NSURL = NSURL(string: url)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request , queue: NSOperationQueue.mainQueue(), completionHandler: { (NSURLResponse, NSData, NSError) -> Void in
                
                
                let img = UIImage(data: NSData)
                cell.imageView?.image = img
                self.imageCache[url] = img
            })
            
        }else{
            cell.imageView?.image = image
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let firstDictionary:NSDictionary = self.tableData[indexPath.row] as NSDictionary
        let audioUrl:String = firstDictionary["url"] as String
        onSetAudio(audioUrl)
        let imageUrl:String = firstDictionary["picture"] as String
        onSetImage(imageUrl)
    }
    
    func didRecieveResults(results: NSDictionary) {
//        println(results)
        if (results["song"] != nil) {
            
            self.tableData=results["song"] as NSArray
            
            self.tv.reloadData()
            
            let firstDictionary:NSDictionary = self.tableData[0] as NSDictionary
            let audioUrl:String = firstDictionary["url"] as String
            onSetAudio(audioUrl)
            let imageUrl:String = firstDictionary["picture"] as String
            onSetImage(imageUrl)
            
        }else  if (results["channels"] != nil){
            self.channelData = results["channels"] as NSArray
            
        }
    
    
    }
    func onSetAudio(url:String){
        timer?.invalidate()
        playTime.text = "00:00"
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target:self, selector:"onUpdate", userInfo: nil, repeats: true)
        btnPlay.removeGestureRecognizer(tap)
        iv.addGestureRecognizer(tap)
        btnPlay.hidden = true 
        
    }
    func onUpdate(){
        let c = audioPlayer.currentPlaybackTime
        if c>0.0{
            let t = audioPlayer.duration
            let p = CFloat(c/t)
            progressView.setProgress(p, animated: true)
            // 总的秒数
            let all:Int = Int(c)
            // 分钟
            let minute:Int = Int(all/60)
            // 秒数
            let second:Int = all%60
            var time:String = ""
            
            if second<10 {
                time = "0\(second)"
            }else{
                time = "\(second)"
            }
            if minute<10 {
                time = "0\(minute):" + time
            }else{
                time = "\(minute):" + time
            }
            playTime.text = time
        }
    }
    func onSetImage(url:String){
        let image = self.imageCache[url]
        
        if !(image != nil) {
            let imgURL:NSURL = NSURL(string: url)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request , queue: NSOperationQueue.mainQueue(), completionHandler: { (NSURLResponse, NSData, NSError) -> Void in
                let img = UIImage(data: NSData)
                self.iv.image = img
                self.imageCache[url] = img
            })
            
        }else{
                self.iv.image = image
        }
    }
    
    //页面跳转的时候把数据传回来
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var channelC:ChannelController = segue.destinationViewController as ChannelController
        channelC.delegate = self
        channelC.channelData = self.channelData
    }
    func onChangeChannel(channel_id: String) {
        println(channel_id)
        let url = "http://douban.fm/j/mine/playlist?\(channel_id)"
        eHttp.onSearch(url)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath){
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        
//    }

}

