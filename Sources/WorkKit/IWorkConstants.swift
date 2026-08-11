import Foundation

// MARK: - iWork Constants

/// Constants and enumerations used for parsing and processing iWork documents.
public enum IWorkConstants {

  // MARK: - Root Object IDs

  static let documentID: UInt64 = 1
  static let packageID: UInt64 = 2

  // MARK: - System Constants

  /// Reference epoch for Apple/Cocoa timestamps (January 1, 2001 UTC).
  static let epoch = Date(timeIntervalSince1970: 978_307_200)

  static let secondsInHour: Double = 3600
  static let secondsInDay: Double = 86400
  static let secondsInWeek: Double = 604800

  /// Decimal128 bias for unpacking decimal values.
  static let decimal128Bias: Int = 0x1820

  // MARK: - File Format Constants

  /// Special value indicating automatic decimal places.
  static let decimalPlacesAuto: UInt8 = 253

  /// Cell type value for currency cells.
  static let currencyCellType: UInt8 = 10

  /// Placeholder character for custom text formatting.
  static let customTextPlaceholder = "\u{E421}"

  // MARK: - Operator Precedence

  /// Operator precedence values for formula parsing.
  static let operatorPrecedence: [String: Int] = [
    "%": 6,
    "^": 5,
    "×": 4,
    "*": 4,
    "/": 4,
    "÷": 4,
    "+": 3,
    "-": 3,
    "&": 2,
  ]

  // MARK: - Numbers Limits

  static let maxTileSize = 256
  static let maxRowCount = 1_000_000
  static let maxColCount = 1_000
  static let maxHeaderCount = 5
  static let maxSignificantDigits = 15
  static let maxBase = 36

  // MARK: - Currency Codes

  static let currencies = [
    "ADP", "AED", "AFA", "AFN", "ALK", "ALL", "AMD", "ANG", "AOA", "AOK",
    "AON", "AOR", "ARA", "ARL", "ARM", "ARP", "ARS", "ATS", "AUD", "AWG",
    "AZM", "AZN", "BAD", "BAM", "BAN", "BBD", "BDT", "BEC", "BEF", "BEL",
    "BGL", "BGM", "BGN", "BGO", "BHD", "BIF", "BMD", "BND", "BOB", "BOL",
    "BOP", "BOV", "BRB", "BRC", "BRE", "BRL", "BRN", "BRR", "BRZ", "BSD",
    "BTN", "BUK", "BWP", "BYB", "BYN", "BYR", "BZD", "CAD", "CDF", "CHE",
    "CHF", "CHW", "CLE", "CLF", "CLP", "CNH", "CNX", "CNY", "COP", "COU",
    "CRC", "CSD", "CSK", "CUC", "CUP", "CVE", "CYP", "CZK", "DDM", "DEM",
    "DJF", "DKK", "DOP", "DZD", "ECS", "ECV", "EEK", "EGP", "EQE", "ERN",
    "ESA", "ESB", "ESP", "ETB", "EUR", "FIM", "FJD", "FKP", "FRF", "GBP",
    "GEK", "GEL", "GHC", "GHS", "GIP", "GMD", "GNF", "GNS", "GQE", "GRD",
    "GTQ", "GWE", "GWP", "GYD", "HKD", "HNL", "HRD", "HRK", "HTG", "HUF",
    "IDR", "IEP", "ILP", "ILR", "ILS", "INR", "IQD", "IRR", "ISJ", "ISK",
    "ITL", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRH",
    "KRO", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL",
    "LSM", "LTL", "LTT", "LUC", "LUF", "LUL", "LVL", "LVR", "LYD", "MAD",
    "MAF", "MCF", "MDC", "MDL", "MGA", "MGF", "MKD", "MKN", "MLF", "MMK",
    "MNT", "MOP", "MRO", "MRU", "MTL", "MTP", "MUR", "MVP", "MVR", "MWK",
    "MXN", "MXP", "MXV", "MYR", "MZE", "MZM", "MZN", "NAD", "NGN", "NIC",
    "NIO", "NLG", "NOK", "NPR", "NZD", "OMR", "PAB", "PEI", "PEN", "PES",
    "PGK", "PHP", "PKR", "PLN", "PLZ", "PTE", "PYG", "QAR", "RHD", "ROL",
    "RON", "RSD", "RUB", "RUR", "RWF", "SAR", "SBD", "SCR", "SDD", "SDG",
    "SDP", "SEK", "SGD", "SHP", "SIT", "SKK", "SLE", "SLL", "SOS", "SRD",
    "SRG", "SSP", "STD", "STN", "SUR", "SVC", "SYP", "SZL", "THB", "TJR",
    "TJS", "TMM", "TMT", "TND", "TOP", "TPE", "TRL", "TRY", "TTD", "TWD",
    "TZS", "UAH", "UAK", "UGS", "UGX", "USD", "USN", "USS", "UYI", "UYP",
    "UYU", "UYW", "UZS", "VEB", "VEF", "VES", "VND", "VNN", "VUV", "WST",
    "XAF", "XAG", "XAU", "XBA", "XBB", "XBC", "XBD", "XCD", "XDR", "XEU",
    "XFO", "XFU", "XOF", "XPD", "XPF", "XPT", "XRE", "XSU", "XTS", "XUA",
    "XXX", "YDD", "YER", "YUD", "YUM", "YUN", "YUR", "ZAL", "ZAR", "ZMK",
    "ZMW", "ZRN", "ZRZ", "ZWD", "ZWL", "ZWR",
  ]

  static let currencySymbols: [String: String] = [
    "AUD": "A$",
    "BRL": "R$",
    "CAD": "CA$",
    "CNY": "CN¥",
    "EUR": "€",
    "GBP": "£",
    "HKD": "HK$",
    "ILS": "₪",
    "INR": "₹",
    "JPY": "JP¥",
    "KRW": "₩",
    "MXN": "MX$",
    "NZD": "NZ$",
    "TWD": "NT$",
    "USD": "$",
    "VND": "₫",
    "XAF": "FCFA",
    "XCD": "EC$",
    "XOF": "CFA",
    "XPF": "CFPF",
  ]

  // MARK: - Helper Functions

  /// Returns the symbol for a given currency code.
  ///
  /// - Parameter code: The ISO 4217 currency code.
  /// - Returns: The currency symbol, or the code itself if no symbol is defined.
  static func symbol(forCurrency code: String) -> String {
    return currencySymbols[code] ?? code
  }

  /// Validates if a currency code is recognized.
  ///
  /// - Parameter code: The ISO 4217 currency code to validate.
  /// - Returns: True if the currency code is recognized.
  static func isValidCurrency(_ code: String) -> Bool {
    return currencies.contains(code)
  }

  /// Converts Apple epoch-based timestamp to Date.
  ///
  /// - Parameter timestamp: Seconds since Apple's reference epoch (January 1, 2001).
  /// - Returns: The corresponding Date.
  static func date(fromAppleTimestamp timestamp: Double) -> Date {
    return Date(timeIntervalSince1970: timestamp + epoch.timeIntervalSince1970)
  }

  /// Converts Date to Apple epoch-based timestamp.
  ///
  /// - Parameter date: The date to convert.
  /// - Returns: Seconds since Apple's reference epoch (January 1, 2001).
  static func appleTimestamp(from date: Date) -> Double {
    return date.timeIntervalSince1970 - epoch.timeIntervalSince1970
  }
}

// MARK: - Cell Storage Flags

/// Flags that indicate which data fields are present in a cell's storage buffer.
struct CellStorageFlags: OptionSet {
  let rawValue: UInt32

  /// Cell contains a Decimal128 value.
  static let hasDecimal128 = CellStorageFlags(rawValue: 0x1)

  /// Cell contains a double-precision floating point value.
  static let hasDouble = CellStorageFlags(rawValue: 0x2)

  /// Cell contains a timestamp value in seconds.
  static let hasSeconds = CellStorageFlags(rawValue: 0x4)

  /// Cell contains a string identifier reference.
  static let hasStringID = CellStorageFlags(rawValue: 0x8)

  /// Cell contains a rich text identifier reference.
  static let hasRichTextID = CellStorageFlags(rawValue: 0x10)

  /// Cell contains a cell style identifier reference.
  static let hasCellStyleID = CellStorageFlags(rawValue: 0x20)

  /// Cell contains a text style identifier reference.
  static let hasTextStyleID = CellStorageFlags(rawValue: 0x40)

  /// Cell contains a conditional format identifier reference.
  static let hasConditionalFormatID = CellStorageFlags(rawValue: 0x80)

  /// Cell contains a format identifier reference.
  static let hasFormatID = CellStorageFlags(rawValue: 0x100)

  /// Cell contains a formula identifier reference.
  static let hasFormulaID = CellStorageFlags(rawValue: 0x200)

  /// Cell contains a control identifier reference.
  static let hasControlID = CellStorageFlags(rawValue: 0x400)

  /// Cell contains a comment identifier reference.
  static let hasCommentID = CellStorageFlags(rawValue: 0x800)

  /// Cell contains a suggestion identifier reference.
  static let hasSuggestionID = CellStorageFlags(rawValue: 0x1000)

  /// Cell contains a number format identifier reference.
  static let hasNumberFormatID = CellStorageFlags(rawValue: 0x2000)

  /// Cell contains a currency format identifier reference.
  static let hasCurrencyFormatID = CellStorageFlags(rawValue: 0x4000)

  /// Cell contains a date format identifier reference.
  static let hasDateFormatID = CellStorageFlags(rawValue: 0x8000)

  /// Cell contains a duration format identifier reference.
  static let hasDurationFormatID = CellStorageFlags(rawValue: 0x10000)

  /// Cell contains a text format identifier reference.
  static let hasTextFormatID = CellStorageFlags(rawValue: 0x20000)

  /// Cell contains a boolean format identifier reference.
  static let hasBooleanFormatID = CellStorageFlags(rawValue: 0x40000)
}

// MARK: - Cell Types

/// The fundamental type of data stored in a cell.
enum CellType: UInt8 {
  case empty = 1
  case number = 2
  case text = 3
  case date = 4
  case boolean = 5
  case duration = 6
  case error = 7
  case richText = 8
  case currency = 10
  case merged = 102
}

/// The value type used in cell value representations.
enum CellValueType: UInt8 {
  case null = 1
  case boolean = 2
  case date = 3
  case number = 4
  case string = 5
}

// MARK: - Cell Formatting

/// Format types for cell data presentation.
enum FormatType: Int {
  case boolean = 1
  case decimal = 256
  case currency = 257
  case percent = 258
  case scientific = 259
  case text = 260
  case date = 261
  case fraction = 262
  case checkbox = 263
  case rating = 267
  case duration = 268
  case base = 269
  case customNumber = 270
  case customText = 271
  case customDate = 272
  case customCurrency = 274
}

/// Formatting types for cell appearance and behavior.
enum FormattingType: Int {
  case base = 1
  case currency = 2
  case datetime = 3
  case fraction = 4
  case number = 5
  case percentage = 6
  case scientific = 7
  case checkbox = 8
  case rating = 9
  case slider = 10
  case stepper = 11
  case popup = 12
  case text = 13
}

/// Formatting types available for control cells.
enum ControlFormattingType: Int {
  case base = 1
  case currency = 2
  case fraction = 4
  case number = 5
  case percentage = 6
  case scientific = 7
}

/// The interaction type for cells with controls.
enum CellInteractionType: Int {
  case valueEditing = 0
  case formulaEditing = 1
  case stock = 2
  case categorySummary = 3
  case stepper = 4
  case slider = 5
  case rating = 6
  case popup = 7
  case toggle = 8
}

/// Maps formatting types to their corresponding cell interaction types.
extension FormattingType {
  var controlCellType: CellInteractionType? {
    switch self {
    case .popup: return .popup
    case .slider: return .slider
    case .stepper: return .stepper
    default: return nil
    }
  }

  var formatType: FormatType {
    switch self {
    case .base: return .base
    case .currency: return .currency
    case .datetime: return .date
    case .fraction: return .fraction
    case .number: return .decimal
    case .percentage: return .percent
    case .popup: return .text
    case .rating: return .rating
    case .scientific: return .scientific
    case .slider: return .decimal
    case .stepper: return .decimal
    case .checkbox: return .checkbox
    case .text: return .text
    }
  }
}

// MARK: - Number Formatting

/// How negative numbers are displayed.
enum NegativeNumberStyle: Int {
  /// Negative numbers use a simple minus sign.
  case minus = 0

  /// Negative numbers are red with no minus sign.
  case red = 1

  /// Negative numbers are in parentheses with no minus sign.
  case parentheses = 2

  /// Negative numbers are red and in parentheses with no minus sign.
  case redAndParentheses = 3
}

/// Padding style for numbers in custom formats.
enum PaddingType: Int {
  /// No padding applied.
  case none = 0

  /// Pad integers with leading zeros and decimals with trailing zeros.
  case zeros = 1

  /// Pad integers with leading spaces and decimals with trailing spaces.
  case spaces = 2
}

/// Padding character for cell content.
enum CellPadding: Int {
  case space = 1
  case zero = 2
}

/// Accuracy level for fraction display.
enum FractionAccuracy: UInt32 {
  /// Fractions are formatted with up to 3 digits in the denominator.
  case three = 0xFFFF_FFFD

  /// Fractions are formatted with up to 2 digits in the denominator.
  case two = 0xFFFF_FFFE

  /// Fractions are formatted with up to 1 digit in the denominator.
  case one = 0xFFFF_FFFF

  /// Fractions are formatted to the nearest half.
  case halves = 2

  /// Fractions are formatted to the nearest quarter.
  case quarters = 4

  /// Fractions are formatted to the nearest eighth.
  case eighths = 8

  /// Fractions are formatted to the nearest sixteenth.
  case sixteenths = 16

  /// Fractions are formatted to the nearest tenth.
  case tenths = 10

  /// Fractions are formatted to the nearest hundredth.
  case hundredths = 100
}

// MARK: - Duration Formatting

/// Display style for duration values.
enum DurationStyle: Int {
  case compact = 0
  case short = 1
  case long = 2
}

/// Units available for duration display.
struct DurationUnits: OptionSet {
  let rawValue: Int

  static let none: DurationUnits = []
  static let week = DurationUnits(rawValue: 1)
  static let day = DurationUnits(rawValue: 2)
  static let hour = DurationUnits(rawValue: 4)
  static let minute = DurationUnits(rawValue: 8)
  static let second = DurationUnits(rawValue: 16)
  static let millisecond = DurationUnits(rawValue: 32)
}

// MARK: - Custom Formatting

/// Custom formatting types for cells.
enum CustomFormattingType: Int {
  case number = 101
  case datetime = 102
  case text = 103
}

extension CustomFormattingType {
  var formatType: FormatType {
    switch self {
    case .number: return .customNumber
    case .datetime: return .customDate
    case .text: return .customText
    }
  }
}

// MARK: - Owner Kinds

/// The type of owner for a cell or drawable.
enum OwnerKind: Int {
  case tableModel = 1
  case mergeOwner = 5
  case hauntedOwner = 35
}
