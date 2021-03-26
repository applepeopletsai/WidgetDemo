//
//  Widget.swift
//  Widget
//
//  Created by Daniel on 2021/3/26.
//

//https://www.jianshu.com/p/94a98c203763
//https://www.youtube.com/watch?v=wOrkcdeui4U
//https://misomiso43.medium.com/%E5%88%9D%E6%8E%A2-widget-extension-in-ios-14-e89cef6c7e50

import WidgetKit
import SwiftUI
import Intents

// 為Widget展示提供一切必要信息的結構體，遵守TimelineProvider協議，產生一個時間線，告訴WidgetKit何時渲染與刷新 Widget，時間線包含一個你定義的自定義TimelineEntry類型。時間線標識了你希望WidgetKit更新Widget內容的日期。在自定義類型中包含你的Widget的視圖需要渲染的屬性。
struct Provider: IntentTimelineProvider {
    // 提供一個默認的View，例如網絡請求失敗、發生未知錯誤、第一次展示Widget都會展示這個view
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    // 為了在Widget庫中顯示Widget，WidgetKit要求Provider提供預覽快照，在組件的添加頁面可以看到效果
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    // 在這個方法內可以進行網絡請求，拿到的數據保存在對應的entry中，調用completion之後會到刷新Widget
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        
        // policy：
        // .never：不刷新
        // .atEnd：Timeline 中最後一個Entry顯示完畢之後自動刷新。getTimeline方法會重新調用
        // .after(date)：到達某個特定時間後自動刷新
        // Timeline的刷新策略是會延遲的，並不一定根據你設定的時間精確刷新。同時官方說明瞭每個widget窗口小部件每天接收的刷新都會有數量限制
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


// 渲染Widget所需的數據模型，需要遵守TimelineEntry協議
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

// 屏幕上Widget顯示的內容，可以針對不同尺寸的Widget設置不同的View。
struct WidgetEntryView : View {
    var entry: Provider.Entry

    //尺寸環境變數
    @Environment(\.widgetFamily) var family
    
    //Widget一共有三種尺寸：systemSmall、systemMedium、systemLarge
    //Small widget只能用widgetURL，且只能傳一個url
    //Medium與Large widget可用widgetURL或Link處理多種url
    var body: some View {
        switch family {
        case .systemSmall:
            VStack {
                Text("SmallWidget")
                    .widgetURL(URL(string: "https://www.apple.com/SmallWidget")!)
                    .background(Color.red)
                Text(entry.date, style: .time)
            }
        default:
            VStack {
                HStack {
                    ForEach(0..<2) { i in
                        Link(destination: URL(string: "https://www.apple.com/\(family == .systemMedium ? "MediumWidget" : "LargeWidget")\(i)")!, label: {
                            Text(family == .systemMedium ? "MediumWidget:\(i)" : "LargeWidget:\(i)")
                        })
                        .background(Color.red)
                    }
                    .widgetURL(URL(string: "https://www.apple.com/tapOnWidget"))
                }
                Text(entry.date, style: .time)
            }
        }
    }
}

@main // 代表著Widget的主入口，系統從這裡加載，可用於多Widget實現
struct WidgetView: Widget {
    let kind: String = "Widget" // Widget的唯一標識

    // WidgetConfiguration：初始化配置代碼
    // StaticConfiguration：可以在不需要用戶任何輸入的情況下自行解析，可以在Widget的App中獲取相關數據併發送給Widget
    // IntentConfiguration：主要針對於具有用戶可配置屬性的Widget，依賴於App的Siri Intent，會自動接收這些Intent並用於更新Widget，用於構建動態Widget
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("測試Wedgit")// 添加編輯界面展示的標題
        .description("This is an example widget.")// 添加編輯界面展示的描述內容
//        .supportedFamilies([.systemSmall,.systemMedium])// 設置Widget支持的控件大小，不設置則默認三個樣式都實現
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
