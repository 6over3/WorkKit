import Foundation

struct IWorkTableCoordinate: Hashable, Sendable {
  let row: Int
  let column: Int
}

struct IWorkTableExtent: Equatable, Sendable {
  let rows: Int
  let columns: Int
}

struct IWorkTableMerge: Equatable, Sendable {
  let origin: IWorkTableCoordinate
  let rowSpan: Int
  let columnSpan: Int
}

func iWorkTableCoordinate(_ cell: TST_CellID) -> IWorkTableCoordinate {
  if cell.hasExpandedCoord,
    cell.expandedCoord.hasRow,
    cell.expandedCoord.hasColumn
  {
    return IWorkTableCoordinate(
      row: Int(cell.expandedCoord.row),
      column: Int(cell.expandedCoord.column)
    )
  }
  return IWorkTableCoordinate(
    row: Int(cell.packedData >> 16),
    column: Int(cell.packedData & 0xFFFF)
  )
}

func iWorkTableExtent(_ size: TST_TableSize) -> IWorkTableExtent {
  let rows = size.hasNumRows ? size.numRows : size.packedData >> 16
  let columns = size.hasNumColumns ? size.numColumns : size.packedData & 0xFFFF
  return IWorkTableExtent(rows: Int(rows), columns: Int(columns))
}
