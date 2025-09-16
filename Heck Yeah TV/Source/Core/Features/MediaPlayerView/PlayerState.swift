//
//  PlayerState.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

enum PlayerState: Equatable {
    case idle
    case starting
    case recordingAndPlaying
    case pausedPlayback
    case stopping
    case error(String)
}


/*
 
 idle > starting > recordingAndPlaying
 
 recordingAndPlaying > stopping > idle
 
 recordingAndPlaying > pausedPlayback
 
 pausedPlayback > recordingAndPlaying
 
 */
