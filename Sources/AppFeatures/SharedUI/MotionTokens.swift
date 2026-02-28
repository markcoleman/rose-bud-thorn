import SwiftUI

public enum MotionTokens {
    public static let quick = Animation.spring(duration: 0.22)
    public static let smooth = Animation.easeInOut(duration: 0.30)
    public static let subtle = Animation.easeInOut(duration: 0.18)
    public static let tabSwitch = Animation.spring(duration: 0.24)
}
