//
//  BalanceWidgetBundle.swift
//  BalanceWidget
//
//  Created by Tom Speake on 6/24/25.
//

import WidgetKit
import SwiftUI

@main
struct BalanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        BalanceWidgetControl()
        BalanceWidgetLiveActivity()
    }
}
