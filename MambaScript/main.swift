#!/usr/bin/swift

import Foundation

struct Medal {
    let position: Int
    let country: String
    let goldCount: Int
    let silverCount: Int
    let bronzeCount: Int
    let totalCount: Int
    
    init(json: [String: AnyObject]) {
        position = json["place"] as? Int ?? 0
        country = json["country_name"] as? String ?? ""
        goldCount = json["gold_count"] as? Int ?? 0
        silverCount = json["silver_count"] as? Int ?? 0
        bronzeCount = json["bronze_count"] as? Int ?? 0
        totalCount = json["total_count"] as? Int ?? 0
    }
}

func runCommand(_ args : String...) -> (output: String, exitCode: Int32) {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    let outpipe = Pipe()
    task.standardOutput = outpipe
    task.launch()
    task.waitUntilExit()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
//    let length = outdata.count
//    var values = [UInt8](repeatElement(0, count: length))
//    outdata.copyBytes(to: &values, count: length)
//    let string = String.init(cString: values)
    
    let string = NSString(data: outdata, encoding: String.Encoding.utf8.rawValue) as? String ?? ""
    
    let status = task.terminationStatus
    
    return (string, status)
}


func printMedals(_ medals: [Medal], count: Int = 0) {
    let header = String(format:"%2@ %3@   %3@   %3@    %4@  \t%@", "Rank", "G", "S", "B", "T", "Country")
    var arrayDot: [String] = []
    for _ in 0..<header.characters.count {
        arrayDot.append("-")
    }
    print(arrayDot.joined())
    print(header)
    print(arrayDot.joined())
    
    var printCount = medals.count
    if count > 0 && count < printCount { printCount = count }
    medals[0..<printCount].forEach {
        print(String(format:"%2d. %3d %3d %3d %4d  \t%@", $0.position, $0.goldCount, $0.silverCount, $0.bronzeCount, $0.totalCount, $0.country))
    }
    print(arrayDot.joined())
}

// Get medals
func getMedals(_ count: Int = 0) {
    let jsonResult = runCommand("curl", "-s", "http://www.medalbot.com/api/v1/medals").output
    guard let jsonData = jsonResult.data(using: String.Encoding.utf8),
    let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
    let jsonArray = json as? [[String: AnyObject]] else { return }
    let medals = jsonArray.map { return Medal(json: $0) }
    printMedals(medals, count: count)
}

func getMedals(forCountry country: String) {
    let jsonResult = runCommand("curl", "-s", "http://www.medalbot.com/api/v1/medals/\(country)").output
    guard let jsonData = jsonResult.data(using: String.Encoding.utf8),
        let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
        let jsonObj = json as? [String: AnyObject] else { return }
    let medal = Medal(json: jsonObj)
    printMedals([medal])
}

func readInput() {
    let country = CommandLine.arguments[1]
    let count = Int(CommandLine.arguments[1]) ?? 0
    if country.characters.count > 2 {
        getMedals(forCountry: country.lowercased())
    } else {
        getMedals(count)
    }
}

readInput()
