//
//  Logger.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 3/2/25.
//

import Foundation
import OSLog

/*
 Log Levels:
.debug("Debug message")
.info("Informational message")
.notice("Important notice")
.warning("Potential issue")
.error("An error occurred")
.fault("Critical system issue") //does **not** stop execution of app
*/


extension Logger {
    static let appLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pullscription.tools", category: "General")
}

