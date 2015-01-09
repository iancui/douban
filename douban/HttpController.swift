

import UIKit

protocol HttpProtocol{
    func didRecieveResults(results:NSDictionary)
}

class HttpController:NSObject{
    
    var delegate:HttpProtocol?
    
    func onSearch(url:String){
        var nsUrl = NSURL(string: url)
        var request = NSURLRequest(URL: nsUrl!)
        //异步获取数据
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(),completionHandler : { (NSURLResponse, NSData, NSError) -> Void in
            var jsonResult:NSDictionary = NSJSONSerialization.JSONObjectWithData(NSData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
            self.delegate?.didRecieveResults(jsonResult)
        })
    }
}
