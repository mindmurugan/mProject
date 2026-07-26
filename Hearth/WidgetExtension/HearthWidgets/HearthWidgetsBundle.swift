import WidgetKit
import SwiftUI

@main
struct HearthWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskChecklistWidget()
        TomorrowAgendaWidget()
    }
}
