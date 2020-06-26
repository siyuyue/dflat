import Foundation

enum EnumTypeEnum: String, Decodable {
  case none = ""
  case `struct` = "struct"
}

struct EnumVal: Decodable {
  var name: String
  var type: EnumTypeEnum
  var `struct`: String?
  var value: Int
}

struct Enum: Decodable {
  var name: String
  var isUnion: Bool
  var namespace: [String]
  var underlyingType: String?
  var fields: [EnumVal]
}

enum ElementTypeEnum: String, Decodable {
  case none = ""
  case `struct` = "struct"
  case utype = "utype"
  case union = "union"
  case `enum` = "enum"
  case bool = "bool"
  case byte = "byte"
  case ubyte = "ubyte"
  case short = "short"
  case ushort = "ushort"
  case int = "int"
  case uint = "uint"
  case long = "long"
  case ulong = "ulong"
  case float = "float"
  case double = "double"
  case string = "string"
}

struct ElementType: Decodable {
  var type: ElementTypeEnum
  var `struct`: String?
  var utype: String?
  var union: String?
  var `enum`: String?
}

enum TypeEnum: String, Decodable {
  case none = ""
  case vector = "vector"
  case `struct` = "struct"
  case utype = "utype"
  case union = "union"
  case `enum` = "enum"
  case bool = "bool"
  case byte = "byte"
  case ubyte = "ubyte"
  case short = "short"
  case ushort = "ushort"
  case int = "int"
  case uint = "uint"
  case long = "long"
  case ulong = "ulong"
  case float = "float"
  case double = "double"
  case string = "string"
}

struct Type: Decodable {
  var type: TypeEnum
  var element: ElementType?
  var `struct`: String?
  var utype: String?
  var union: String?
  var `enum`: String?
}

struct Field: Decodable {
  var name: String
  var type: Type
  var `default`: String?
  var deprecated: Bool
  var attributes: [String]
  var key: String?
}

struct Struct: Decodable {
  var name: String
  var fixed: Bool
  var namespace: [String]
  var fields: [Field]
}

struct Schema: Decodable {
  var enums: [Enum]
  var structs: [Struct]
  var root: String
}

var SwiftType: [String: String] = [
  "utype": "UInt8",
  "bool": "Bool",
  "byte": "Int8",
  "ubyte": "UInt8",
  "short": "Int16",
  "ushort": "UInt16",
  "int": "Int32",
  "uint": "UInt32",
  "long": "Int64",
  "ulong": "UInt64",
  "float": "Float32",
  "double": "Double",
  "string": "String?",
]

var SQLiteType: [String: String] = [
  "utype": "INTEGER",
  "union": "INTEGER",
  "enum": "INTEGER",
  "bool": "INTEGER",
  "byte": "INTEGER",
  "ubyte": "INTEGER",
  "short": "INTEGER",
  "ushort": "INTEGER",
  "int": "INTEGER",
  "uint": "INTEGER",
  "long": "INTEGER",
  "ulong": "INTEGER",
  "float": "REAL",
  "double": "REAL",
  "string": "TEXT",
]

extension String {
  func firstLowercased() -> String {
    prefix(1).lowercased() + dropFirst()
  }
  func firstUppercased() -> String {
    prefix(1).uppercased() + dropFirst()
  }
}

extension Field {
  var isPrimary: Bool {
    attributes.contains("primary")
  }
  var isUnique: Bool {
    attributes.contains("unique")
  }
  var hasIndex: Bool {
    attributes.contains("indexed") || attributes.contains("unique")
  }
}

extension Enum {
  func findEnumVal(_ value: Int) -> EnumVal? {
    for field in fields {
      if field.value == value {
        return field
      }
    }
    return nil
  }
}

var enumDefs = [String: Enum]()
var structDefs = [String: Struct]()
var DflatGenNamespace = ""

func SetNamespace(_ namespace: [String], previous pns: inout [String], code: inout String) {
  guard namespace != pns else { return }
  if pns.count > 0 {
    code += "\n}\n\n// MARK: - \(pns.joined(separator: "."))\n"
  }
  // This is actually not right. If we previously declared, we need to use extension Namespace1.Namespace2 instead.
  if namespace.count > 0 {
    code += "\nextension \(namespace.joined(separator: ".")) {\n"
  }
  pns = namespace
}

func GenEnumDataModel(_ enumDef: Enum, code: inout String) {
  code += "\npublic enum \(enumDef.name): \(SwiftType[enumDef.underlyingType!]!), DflatFriendlyValue {\n"
  for field in enumDef.fields {
    code += "  case \(field.name.firstLowercased()) = \(field.value)\n"
  }
  code += "  public static func < (lhs: \(enumDef.name), rhs: \(enumDef.name)) -> Bool {\n"
  code += "    return lhs.rawValue < rhs.rawValue\n"
  code += "  }\n"
  code += "}\n"
}

func GenUnionDataModel(_ enumDef: Enum, code: inout String) {
  code += "\npublic enum \(enumDef.name): Equatable {\n"
  for field in enumDef.fields {
    guard field.name != "NONE" else { continue }
    code += "  case \(field.name.firstLowercased())(_: \(field.name))\n"
  }
  code += "}\n"
}

func GetElementType(_ type: ElementType) -> String {
  switch type.type {
  case .struct:
    return type.struct!
  case .utype:
    return ""
  case .union:
    return type.union!
  case .enum:
    return type.enum!
  default:
    return SwiftType[type.type.rawValue]!
  }
}

func IsScalarElementType(_ type: ElementType) -> Bool {
  switch type.type {
  case .struct:
    return false
  case .utype:
    return false
  case .union:
    return false
  case .enum:
    return false
  case .string:
    return false
  default:
    return true
  }
}

func GetFieldType(_ field: Field) -> String {
  var fieldType: String
  switch field.type.type {
  case .struct:
    fieldType = field.type.struct! + "?"
  case .vector:
    fieldType = "[\(GetElementType(field.type.element!))]"
  case .utype:
    fieldType = ""
  case .union:
    fieldType = field.type.union! + "?"
  case .enum:
    fieldType = field.type.enum!
  default:
    fieldType = SwiftType[field.type.type.rawValue]!
  }
  if field.isPrimary {
    if fieldType.suffix(1) == "?" {
      fieldType.removeLast()
    }
  }
  return fieldType
}

func GetFieldRequiredType(_ field: Field) -> String {
  var fieldType = GetFieldType(field)
  if fieldType.suffix(1) == "?" {
    fieldType.removeLast()
  }
  return fieldType
}

func IsDataField(_ field: Field) -> Bool {
  if field.deprecated {
    return false
  }
  if field.type.type == .utype {
    return false
  }
  if field.type.type == .vector && field.type.element!.type == .utype {
    return false
  }
  return true
}

func GetFullyQualifiedName(_ structDef: Struct) -> String {
  if structDef.namespace.count > 0 {
    return structDef.namespace.joined(separator: ".") + ".\(structDef.name)"
  } else {
    return structDef.name
  }
}

func GetFullyQualifiedName(_ enumDef: Enum) -> String {
  if enumDef.namespace.count > 0 {
    return enumDef.namespace.joined(separator: ".") + ".\(enumDef.name)"
  } else {
    return enumDef.name
  }
}

func GetEnumDefaultValue(_ en: String) -> String {
    let enumDef = enumDefs[en]!
    let enumVal = enumDef.findEnumVal(0) ?? enumDef.fields.first!
    return ".\(enumVal.name.firstLowercased())"
}

func GetFieldDefaultValue(_ field: Field, required: Bool = false) -> String {
  if let val = field.default {
    if field.type.type == .enum {
      let enumDef = enumDefs[field.type.enum!]!
      let enumVal = enumDef.findEnumVal(Int(val)!)!
      return ".\(enumVal.name.firstLowercased())"
    }
    return val
  }
  if (field.isPrimary || required) && field.type.type == .string {
    return "\"\""
  }
  if field.type.type == .string || field.type.type == .struct ||
     field.type.type == .utype || field.type.type == .union {
    return "nil"
  }
  if field.type.type == .enum {
    return GetEnumDefaultValue(field.type.enum!)
  }
  if field.type.type == .vector {
    return "[]"
  }
  return "0"
}

func GetStructInit(_ structDef: Struct) -> String {
  var parameters = [String]()
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    guard field.isPrimary else { continue }
    parameters.append("\(field.name): \(GetFieldType(field))")
  }
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    guard !field.isPrimary else { continue }
    parameters.append("\(field.name): \(GetFieldType(field)) = \(GetFieldDefaultValue(field))")
  }
  return parameters.joined(separator: ", ")
}

func GetStructDeserializer(_ structDef: Struct) -> String {
  var code = ""
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    switch field.type.type {
    case .struct:
      code += "    self.\(field.name) = obj.\(field.name).map { \(GetFieldRequiredType(field))($0) }\n"
    case .vector:
      if IsScalarElementType(field.type.element!) {
        code += "    self.\(field.name) = obj.\(field.name)\n"
      } else {
        code += "    var __\(field.name) = \(GetFieldType(field))()\n"
        code += "    for i: Int32 in 0..<obj.\(field.name)Count {\n"
        switch field.type.element!.type {
          case .struct:
            code += "      guard let o = obj.\(field.name)(at: i) else { break }\n"
            code += "      __\(field.name).append(\(GetElementType(field.type.element!))(o))\n"
          case .union:
            code += "      guard let ot = obj.\(field.name)Type(at: i) else { break }\n"
            code += "      switch ot {\n"
            code += "      case .none_:\n"
            code += "        fatalError()\n"
            let enumDef = enumDefs[field.type.element!.union!]!
            for enumVal in enumDef.fields {
              guard enumVal.name != "NONE" else { continue }
              code += "      case .\(enumVal.name.firstLowercased()):\n"
              let subStructDef = structDefs[enumVal.struct!]!
              code += "        guard let oe = obj.\(field.name)(at: i, type: \(DflatGenNamespace).\(GetFullyQualifiedName(subStructDef)).self) else { break }\n"
              code += "        __\(field.name).append(.\(enumVal.name.firstLowercased())(\(enumVal.name)(oe)))\n"
            }
            code += "      }\n"
          case .enum:
            code += "      guard let o = obj.\(field.name)(at: i) else { break }\n"
            code += "      __\(field.name).append(\(GetElementType(field.type.element!))(rawValue: o.rawValue) ?? \(GetEnumDefaultValue(field.type.element!.enum!)))\n"
          default:
            fatalError(field.type.element!.type.rawValue)
        }
        code += "    }\n"
        code += "    self.\(field.name) = __\(field.name)\n"
      }
    case .union:
      code += "    switch obj.\(field.name)Type {\n"
      code += "    case .none_:\n"
      code += "      self.\(field.name) = nil\n"
      let enumDef = enumDefs[field.type.union!]!
      for enumVal in enumDef.fields {
        guard enumVal.name != "NONE" else { continue }
        code += "    case .\(enumVal.name.firstLowercased()):\n"
        let subStructDef = structDefs[enumVal.struct!]!
        code += "      self.\(field.name) = obj.\(field.name)(type: \(DflatGenNamespace).\(GetFullyQualifiedName(subStructDef)).self).map { .\(enumVal.name.firstLowercased())(\(enumVal.name)($0)) }\n"
      }
      code += "    }\n"
    case .enum:
      code += "    self.\(field.name) = \(GetFieldType(field))(rawValue: obj.\(field.name).rawValue) ?? \(GetFieldDefaultValue(field))\n"
    case .string:
      if field.isPrimary {
        code += "    self.\(field.name) = obj.\(field.name)!\n"
      } else {
        code += "    self.\(field.name) = obj.\(field.name)\n"
      }
    default:
      code += "    self.\(field.name) = obj.\(field.name)\n"
    }
  }
  return code
}

func GenStructDataModel(_ structDef: Struct, code: inout String) {
  code += "\npublic struct \(structDef.name): Equatable {\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "  var \(field.name): \(GetFieldType(field))\n"
  }
  code += "  public init(\(GetStructInit(structDef))) {\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "    self.\(field.name) = \(field.name)\n"
  }
  code += "  }\n"
  code += "  public init(_ obj: \(DflatGenNamespace).\(GetFullyQualifiedName(structDef))) {\n"
  code += GetStructDeserializer(structDef)
  code += "  }\n"
  code += "}\n"
}

func GenRootDataModel(_ structDef: Struct, code: inout String) {
  code += "\npublic final class \(structDef.name): Dflat.Atom, Equatable {\n"
  code += "  public static func == (lhs: \(structDef.name), rhs: \(structDef.name)) -> Bool {\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "    guard lhs.\(field.name) == rhs.\(field.name) else { return false }\n"
  }
  code += "    return true\n"
  code += "  }\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "  let \(field.name): \(GetFieldType(field))\n"
  }
  code += "  public init(\(GetStructInit(structDef))) {\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "    self.\(field.name) = \(field.name)\n"
  }
  code += "  }\n"
  code += "  public init(_ obj: \(DflatGenNamespace).\(GetFullyQualifiedName(structDef))) {\n"
  code += GetStructDeserializer(structDef)
  code += "  }\n"
  code += "  override public class func fromFlatBuffers(_ bb: ByteBuffer) -> Self {\n"
  code += "    Self(\(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).getRootAs\(structDef.name)(bb: bb))\n"
  code += "  }\n"
  code += "}\n"
}

func GenDataModel(schema: Schema, outputPath: String) {
  var code = "import Dflat\nimport FlatBuffers\n"
  var namespace: [String] = []
  for enumDef in schema.enums {
    SetNamespace(enumDef.namespace, previous: &namespace, code: &code)
    if enumDef.isUnion {
      GenUnionDataModel(enumDef, code: &code)
    } else {
      GenEnumDataModel(enumDef, code: &code)
    }
  }
  for structDef in schema.structs {
    if structDef.name != schema.root {
      SetNamespace(structDef.namespace, previous: &namespace, code: &code)
      GenStructDataModel(structDef, code: &code)
    }
  }
  for structDef in schema.structs {
    if structDef.name == schema.root {
      SetNamespace(structDef.namespace, previous: &namespace, code: &code)
      GenRootDataModel(structDef, code: &code)
      break
    }
  }
  SetNamespace([String](), previous: &namespace, code: &code)
  try! code.write(to: URL(fileURLWithPath: outputPath), atomically: false, encoding: String.Encoding.utf8)
}

func GenEnumSQLiteValue(_ enumDef: Enum, code: inout String) {
  code += "\nextension \(GetFullyQualifiedName(enumDef)): SQLiteValue {\n"
  code += "  public func bindSQLite(_ query: OpaquePointer, parameterId: Int32) {\n"
  code += "    self.rawValue.bindSQLite(query, parameterId: parameterId)\n"
  code += "  }\n"
  code += "}\n"
}

func GenUnionSerializer(_ enumDef: Enum, code: inout String) {
  code += "\nextension \(GetFullyQualifiedName(enumDef)) {\n"
  code += "  func to(flatBufferBuilder: inout FlatBufferBuilder) -> Offset<UOffset> {\n"
  code += "    switch self {\n"
  for enumVal in enumDef.fields {
    guard enumVal.name != "NONE" else { continue }
    code += "    case .\(enumVal.name.firstLowercased())(let o):\n"
    code += "      return o.to(flatBufferBuilder: &flatBufferBuilder)\n"
  }
  code += "    }\n"
  code += "  }\n"
  code += "  var _type: \(DflatGenNamespace).\(GetFullyQualifiedName(enumDef)) {\n"
  code += "    switch self {\n"
  for enumVal in enumDef.fields {
    guard enumVal.name != "NONE" else { continue }
    code += "    case .\(enumVal.name.firstLowercased())(_):\n"
    code += "      return \(DflatGenNamespace).\(GetFullyQualifiedName(enumDef)).\(enumVal.name.firstLowercased())\n"
  }
  code += "    }\n"
  code += "  }\n"
  code += "}\n"
  code += "\nextension Optional where Wrapped == \(GetFullyQualifiedName(enumDef)) {\n"
  code += "  func to(flatBufferBuilder: inout FlatBufferBuilder) -> Offset<UOffset> {\n"
  code += "    self.map { $0.to(flatBufferBuilder: &flatBufferBuilder) } ?? Offset()\n"
  code += "  }\n"
  code += "  var _type: \(DflatGenNamespace).\(GetFullyQualifiedName(enumDef)) {\n"
  code += "    self.map { $0._type } ?? .none_\n"
  code += "  }\n"
  code += "}\n"
}

func GenStructSerializer(_ structDef: Struct, code: inout String) {
  code += "\nextension \(GetFullyQualifiedName(structDef)) {\n"
  if structDef.fixed {
    code += "  func toRawMemory() -> UnsafeMutableRawPointer {\n"
  } else {
    code += "  func to(flatBufferBuilder: inout FlatBufferBuilder) -> Offset<UOffset> {\n"
  }
  var parameters = [String]()
  for field in structDef.fields {
    guard !field.deprecated else { continue }
    switch field.type.type {
    case .struct:
      let subStructDef = structDefs[field.type.struct!]!
      if subStructDef.fixed {
        code += "    let __\(field.name) = self.\(field.name).toRawMemory()\n"
        parameters.append("structOf\(field.name.firstUppercased()): __\(field.name)")
        break
      }
      fallthrough
    case .union:
      code += "    let __\(field.name) = self.\(field.name).to(flatBufferBuilder: &flatBufferBuilder)\n"
      parameters.append("offsetOf\(field.name.firstUppercased()): __\(field.name)")
    case .vector:
      if IsScalarElementType(field.type.element!) {
        code += "    let __\(field.name) = flatBufferBuilder.createVector(self.\(field.name))\n"
        parameters.append("vectorOf\(field.name.firstUppercased()): __\(field.name)")
      } else {
        switch field.type.element!.type {
        case .struct:
          let subStructDef = structDefs[field.type.element!.struct!]!
          if subStructDef.fixed {
            code += "    var __\(field.name) = [UnsafeMutableRawPointer]()\n"
            code += "    for i in self.\(field.name) {\n"
            code += "      __\(field.name).append(i.toRawMemory())\n"
            code += "    }\n"
            code += "    let __vector_\(field.name) = flatBufferBuilder.createVector(structs: __\(field.name), type: \(DflatGenNamespace).\(GetFullyQualifiedName(subStructDef)).self)\n"
            parameters.append("vectorOf\(field.name.firstUppercased()): __vector_\(field.name)")
            break
          }
          fallthrough
        case .union:
          code += "    var __\(field.name) = [Offset<UOffset>]()\n"
          code += "    for i in self.\(field.name) {\n"
          code += "      __\(field.name).append(i.to(flatBufferBuilder: &flatBufferBuilder))\n"
          code += "    }\n"
          code += "    let __vector_\(field.name) = flatBufferBuilder.createVector(ofOffsets: __\(field.name))\n"
          parameters.append("vectorOf\(field.name.firstUppercased()): __vector_\(field.name)")
        case .utype:
          let enumDef = enumDefs[field.type.element!.utype!]!
          let fieldName = field.name.prefix(field.name.count - 5) + "Type"
          code += "    var __\(fieldName) = [\(DflatGenNamespace).\(GetFullyQualifiedName(enumDef))]()\n"
          code += "    for i in self.\(field.name.prefix(field.name.count - 5)) {\n"
          code += "      __\(fieldName).append(i._type)\n"
          code += "    }\n"
          code += "    let __vector_\(fieldName) = flatBufferBuilder.createVector(__\(fieldName))\n"
          parameters.append("vectorOf\(fieldName.prefix(1).uppercased() + fieldName.dropFirst()): __vector_\(fieldName)")
        case .string:
          code += "    var __\(field.name) = [Offset<UOffset>]()\n"
          code += "    for i in \(field.name) {\n"
          code += "      __\(field.name).append(flatBufferBuilder.create(string: i))\n"
          code += "    }\n"
          code += "    let __vector_\(field.name) = flatBufferBuilder.createVector(ofOffsets: __\(field.name))\n"
          parameters.append("vectorOf\(field.name.firstUppercased()): __vector_\(field.name)")
        case .enum:
          let enumDef = enumDefs[field.type.element!.enum!]!
          code += "    var __\(field.name) = [\(DflatGenNamespace).\(GetFullyQualifiedName(enumDef))]()\n"
          code += "    for i in self.\(field.name) {\n"
          code += "      __\(field.name).append(\(DflatGenNamespace).\(GetFullyQualifiedName(enumDef))(rawValue: i.rawValue) ?? \(GetEnumDefaultValue(field.type.element!.enum!)))\n"
          code += "    }\n"
          code += "    let __vector_\(field.name) = flatBufferBuilder.createVector(__\(field.name))\n"
          parameters.append("vectorOf\(field.name.firstUppercased()): __vector_\(field.name)")
        default:
          break
        }
      }
    case .utype:
      let fieldName = field.name.prefix(field.name.count - 5) + "Type"
      code += "    let __\(fieldName) = self.\(field.name.prefix(field.name.count - 5))._type\n"
      parameters.append("\(fieldName): __\(fieldName)")
    case .enum:
      let enumDef = enumDefs[field.type.enum!]!
      code += "    let __\(field.name) = \(DflatGenNamespace).\(GetFullyQualifiedName(enumDef))(rawValue: self.\(field.name).rawValue) ?? \(GetFieldDefaultValue(field))\n"
      parameters.append("\(field.name): __\(field.name)")
    case .string:
      if field.isPrimary {
        code += "    let __\(field.name) = flatBufferBuilder.create(string: self.\(field.name))\n"
      } else {
        code += "    let __\(field.name) = self.\(field.name).map { flatBufferBuilder.create(string: $0) } ?? Offset<String>()\n"
      }
      parameters.append("offsetOf\(field.name.firstUppercased()): __\(field.name)")
    default:
      parameters.append("\(field.name): self.\(field.name)")
    }
  }
  if structDef.fixed {
    code += "    return \(DflatGenNamespace).\(structDef.namespace.joined(separator: ".")).create\(structDef.name)(\(parameters.joined(separator: ", ")))\n"
  } else {
    code += "    return \(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).create\(structDef.name)(&flatBufferBuilder, \(parameters.joined(separator: ", ")))\n"
  }
  code += "  }\n"
  code += "}\n"
  code += "\nextension Optional where Wrapped == \(GetFullyQualifiedName(structDef)) {\n"
  if structDef.fixed {
    code += "  func toRawMemory() -> UnsafeMutableRawPointer? {\n"
    code += "    self.map { $0.toRawMemory() }\n"
  } else {
    code += "  func to(flatBufferBuilder: inout FlatBufferBuilder) -> Offset<UOffset> {\n"
    code += "    self.map { $0.to(flatBufferBuilder: &flatBufferBuilder) } ?? Offset()\n"
  }
  code += "  }\n"
  code += "}\n"
}

enum KeyPath {
  case field(_: Field)
  case union(_: Field, _: EnumVal)
  var name: String {
    switch self {
    case .field(let field):
      return field.name
    case .union(let field, let union):
      return field.name + "__" + union.name
    }
  }
}

func GetKeyName(keyPaths: [KeyPath], field: Field, pkCount: inout Int) -> String {
  if field.isPrimary {
    let key = "__pk\(pkCount)"
    pkCount += 1
    return key
  } else {
    return keyPaths.map { $0.name + "__" }.joined() + field.name
  }
}

func GetTraverseKeyFlatBuffers(_ keyPaths: [KeyPath], defaultValue: String) -> String {
  var code = ""
  for (i, keyPath) in keyPaths.enumerated() {
    switch keyPath {
    case .field(let field):
      code += "    guard let tr\(i + 1) = tr\(i).\(field.name) else { return (\(defaultValue), true) }\n"
    case .union(let field, let union):
      let subStructDef = structDefs[union.struct!]!
      code += "    guard let tr\(i + 1) = tr\(i).\(field.name)(type: \(DflatGenNamespace).\(GetFullyQualifiedName(subStructDef)).self) else { return (\(defaultValue), true) }\n"
    }
  }
  return code
}

func GetTraverseKeyDflat(_ keyPaths: [KeyPath], defaultValue: String) -> String {
  var code = ""
  for (i, keyPath) in keyPaths.enumerated() {
    switch keyPath {
    case .field(let field):
      code += "    guard let or\(i + 1) = or\(i).\(field.name) else { return (\(defaultValue), true) }\n"
    case .union(let field, let union):
      code += "    guard case let .\(union.name.firstLowercased())(or\(i + 1)) = or\(i).\(field.name) else { return (\(defaultValue), true) }\n"
    }
  }
  return code
}

func GetKeyPathQuery(_ keyPaths: [KeyPath], field: Field) -> String {
  return (keyPaths.map {
    switch $0 {
    case .field(let field):
      return field.name
    case .union(let field, let union):
      let structDef = structDefs[union.struct!]!
      return field.name + ".as(\(GetFullyQualifiedName(structDef)).self)"
    }
  } + [field.name]).joined(separator: ".")
}

struct IndexedField {
  var keyPaths: [KeyPath]
  var field: Field
  var keyName: String
}

func GetExpandedName(keyPaths: [KeyPath], field: Field) -> String {
  return keyPaths.map { $0.name + "__" }.joined() + field.name
}

func GetIndexForField(_ structDef: Struct, keyPaths: [KeyPath], field: Field, pkCount: inout Int, indexedFields: inout [IndexedField]) {
  if field.hasIndex {
    precondition(field.type.type != .struct && field.type.type != .vector)
    var keyName = GetExpandedName(keyPaths: keyPaths, field: field)
    if field.type.type == .union { // If we mark a union field as indexed, that means we can speed the query by matching types.
      keyName += "__type"
    }
    indexedFields.append(IndexedField(keyPaths: keyPaths, field: field, keyName: keyName))
  }
  switch field.type.type {
  case .union:
    let unionDef = enumDefs[field.type.union!]!
    for enumVal in unionDef.fields {
      guard enumVal.name != "NONE" else { continue }
      let newKeyPaths = keyPaths + [KeyPath.union(field, enumVal)]
      let subStructDef = structDefs[enumVal.struct!]!
      for field in subStructDef.fields {
        guard IsDataField(field) else { continue }
        GetIndexForField(structDef, keyPaths: newKeyPaths, field: field, pkCount: &pkCount, indexedFields: &indexedFields)
      }
    }
  case .struct:
    let subStructDef = structDefs[field.type.struct!]!
    let newKeyPaths = keyPaths + [KeyPath.field(field)]
    for field in subStructDef.fields {
      guard IsDataField(field) else { continue }
      GetIndexForField(structDef, keyPaths: newKeyPaths, field: field, pkCount: &pkCount, indexedFields: &indexedFields)
    }
  default: // These are the simple types (string, scalar) or enum
    break
  }
}

func GetIndexedFields(_ structDef: Struct) -> [IndexedField] {
  var indexedFields = [IndexedField]()
  var pkCount = 0
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    GetIndexForField(structDef, keyPaths: [], field: field, pkCount: &pkCount, indexedFields: &indexedFields)
  }
  return indexedFields
}

func GetTableName(_ structDef: Struct) -> String {
  var names: [String] = structDef.namespace.map { $0.lowercased() }
  names.append(structDef.name.lowercased())
  return names.joined(separator: "__")
}

func GetPrimaryKeys(_ structDef: Struct) -> [Field] {
  var pk = [Field]()
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    if field.isPrimary {
      pk.append(field)
    }
  }
  return pk
}

func GetDataFields(_ structDef: Struct) -> [Field] {
  return structDef.fields.filter({ IsDataField($0) && $0.isPrimary }) + structDef.fields.filter({ IsDataField($0) && !$0.isPrimary })
}

func GetIndexedFieldExpr(_ structDef: Struct, indexedField: IndexedField) -> String {
  var field = GetKeyPathQuery(indexedField.keyPaths, field: indexedField.field)
  field = GetFullyQualifiedName(structDef) + "." + field
  if indexedField.field.type.type == .union {
    return field + "._type"
  }
  return field
}

func GenChangeRequest(_ structDef: Struct, code: inout String) {
  let indexedFields = GetIndexedFields(structDef)
  let tableName = GetTableName(structDef)
  code += "\nextension \(GetFullyQualifiedName(structDef)): SQLiteDflat.SQLiteAtom {\n"
  code += "  public static var table: String { \"\(GetTableName(structDef))\" }\n"
  code += "  public static var indexFields: [String] { [\(indexedFields.map { "\"\($0.keyName)\"" }.joined(separator: ", "))] }\n"
  code += "  public static func setUpSchema(_ toolbox: PersistenceToolbox) {\n"
  code += "    \(GetFullyQualifiedName(structDef))ChangeRequest.setUpSchema(toolbox)\n"
  code += "  }\n"
  code += "  public static func insertIndex(_ toolbox: PersistenceToolbox, field: String, rowid: Int64, table: ByteBuffer) -> Bool {\n"
  code += "    guard let sqlite = ((toolbox as? SQLitePersistenceToolbox).map { $0.connection }) else { return false }\n"
  code += "    switch field {\n"
  for indexedField in indexedFields {
    code += "    case \"\(indexedField.keyName)\":\n"
    code += "      guard let insert = sqlite.prepareStatement(\"INSERT INTO \(tableName)__\(indexedField.keyName) (rowid, \(indexedField.keyName)) VALUES (?1, ?2)\") else { return false }\n"
    code += "      rowid.bindSQLite(insert, parameterId: 1)\n"
    code += "      let retval = \(GetIndexedFieldExpr(structDef, indexedField: indexedField)).evaluate(object: .table(table))\n"
    code += "      if retval.unknown {\n"
    code += "        sqlite3_bind_null(insert, 2)\n"
    code += "      } else {\n"
    code += "        retval.result.bindSQLite(insert, parameterId: 2)\n"
    code += "      }\n"
    code += "      guard SQLITE_DONE == sqlite3_step(insert) else { return false }\n"
  }
  code += "    default:\n"
  code += "      break\n"
  code += "    }\n"
  code += "    return true\n"
  code += "  }\n"
  code += "}\n"
  if structDef.namespace.count > 0 {
    code += "\nextension \(structDef.namespace.joined(separator: ".")) {\n"
  }
  code += "\npublic final class \(structDef.name)ChangeRequest: Dflat.ChangeRequest {\n"
  code += "  public static var atomType: Any.Type { \(structDef.name).self }\n"
  code += "  public var _type: ChangeRequestType\n"
  code += "  public var _rowid: Int64\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "  public var \(field.name): \(GetFieldType(field))\n"
  }
  code += "  public init(type: ChangeRequestType) {\n"
  code += "    _type = type\n"
  code += "    _rowid = -1\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "    \(field.name) = \(GetFieldDefaultValue(field))\n"
  }
  code += "  }\n"
  code += "  public init(type: ChangeRequestType, _ o: \(structDef.name)) {\n"
  code += "    _type = type\n"
  code += "    _rowid = o._rowid\n"
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    code += "    \(field.name) = o.\(field.name)\n"
  }
  let primaryKeys = GetPrimaryKeys(structDef)
  code += "  }\n"
  code += "  public static func changeRequest(_ o: \(structDef.name)) -> \(structDef.name)ChangeRequest? {\n"
  code += "    let transactionContext = SQLiteTransactionContext.current!\n"
  code += "    let key: SQLiteObjectKey = o._rowid >= 0 ? .rowid(o._rowid) : .primaryKey([\(primaryKeys.map { "o." + $0.name }.joined(separator: ", "))])\n"
  code += "    let u = transactionContext.objectRepository.object(transactionContext.connection, ofType: \(structDef.name).self, for: key)\n"
  code += "    return u.map { \(structDef.name)ChangeRequest(type: .update, $0) }\n"
  code += "  }\n"
  code += "  public static func creationRequest(_ o: \(structDef.name)) -> \(structDef.name)ChangeRequest {\n"
  code += "    let creationRequest = \(structDef.name)ChangeRequest(type: .creation, o)\n"
  code += "    creationRequest._rowid = -1\n"
  code += "    return creationRequest\n"
  code += "  }\n"
  code += "  public static func creationRequest() -> \(structDef.name)ChangeRequest {\n"
  code += "    return \(structDef.name)ChangeRequest(type: .creation)\n"
  code += "  }\n"
  code += "  public static func upsertRequest(_ o: \(structDef.name)) -> \(structDef.name)ChangeRequest {\n"
  code += "    guard let changeRequest = Self.changeRequest(o) else {\n"
  code += "      return Self.creationRequest(o)\n"
  code += "    }\n"
  code += "    return changeRequest\n"
  code += "  }\n"
  code += "  public static func deletionRequest(_ o: \(structDef.name)) -> \(structDef.name)ChangeRequest? {\n"
  code += "    let transactionContext = SQLiteTransactionContext.current!\n"
  code += "    let key: SQLiteObjectKey = o._rowid >= 0 ? .rowid(o._rowid) : .primaryKey([\(primaryKeys.map { "o." + $0.name }.joined(separator: ", "))])\n"
  code += "    let u = transactionContext.objectRepository.object(transactionContext.connection, ofType: \(structDef.name).self, for: key)\n"
  code += "    return u.map { \(structDef.name)ChangeRequest(type: .deletion, $0) }\n"
  code += "  }\n"
  code += "  var _atom: \(structDef.name) {\n"
  code += "    let atom = \(structDef.name)(\(GetDataFields(structDef).map { $0.name + ": " + $0.name }.joined(separator: ", ")))\n"
  code += "    atom._rowid = _rowid\n"
  code += "    return atom\n"
  code += "  }\n"
  code += "  public static func setUpSchema(_ toolbox: PersistenceToolbox) {\n"
  code += "    guard let sqlite = ((toolbox as? SQLitePersistenceToolbox).map { $0.connection }) else { return }\n"
  code += "    sqlite3_exec(sqlite.sqlite, \"CREATE TABLE IF NOT EXISTS \(tableName) (rowid INTEGER PRIMARY KEY AUTOINCREMENT, "
  code += "\(primaryKeys.enumerated().map { "__pk\($0.offset) \(SQLiteType[$0.element.type.type.rawValue]!)" }.joined(separator: ", ")), p BLOB, UNIQUE("
  code += "\(primaryKeys.enumerated().map { "__pk\($0.offset)" }.joined(separator: ", "))))\", nil, nil, nil)\n"
  // TODO: Create table for indexes.
  for indexedField in indexedFields {
    code += "    sqlite3_exec(sqlite.sqlite, \"CREATE TABLE IF NOT EXISTS \(tableName)__\(indexedField.keyName) (rowid INTEGER PRIMARY KEY, \(indexedField.keyName) \(SQLiteType[indexedField.field.type.type.rawValue]!))\", nil, nil, nil)\n"
    code += "    sqlite3_exec(sqlite.sqlite, \"CREATE\(indexedField.field.isUnique ? " UNIQUE" : "") INDEX IF NOT EXISTS index__\(tableName)__\(indexedField.keyName) ON \(tableName)__\(indexedField.keyName) (\(indexedField.keyName))\", nil, nil, nil)\n"
  }
  if indexedFields.count > 0 {
    code += "    sqlite.clearIndexStatus(for: \(structDef.name).table)\n"
  }
  code += "  }\n"
  code += "  public func commit(_ toolbox: PersistenceToolbox) -> UpdatedObject? {\n"
  code += "    guard let toolbox = toolbox as? SQLitePersistenceToolbox else { return nil }\n"
  code += "    let indexSurvey = toolbox.connection.indexSurvey(\(structDef.name).indexFields, table: \(structDef.name).table)\n"
  code += "    switch _type {\n"
  code += "    case .creation:\n"
  code += "      guard let insert = toolbox.connection.prepareStatement(\"INSERT INTO \(tableName) (\(primaryKeys.enumerated().map { "__pk\($0.offset)" }.joined(separator: ", ")), p) VALUES (?1, \(primaryKeys.enumerated().map { "?\($0.offset + 2)" }.joined(separator: ", ")))\") else { return nil }\n"
  for (i, field) in primaryKeys.enumerated() {
    code += "      \(field.name).bindSQLite(insert, parameterId: \(i + 1))\n"
  }
  code += "      let atom = self._atom\n"
  code += "      toolbox.flatBufferBuilder.clear()\n"
  code += "      let offset = atom.to(flatBufferBuilder: &toolbox.flatBufferBuilder)\n"
  code += "      toolbox.flatBufferBuilder.finish(offset: offset)\n"
  code += "      let byteBuffer = toolbox.flatBufferBuilder.buffer\n"
  code += "      let memory = byteBuffer.memory.advanced(by: byteBuffer.reader)\n"
  code += "      let SQLITE_STATIC = unsafeBitCast(OpaquePointer(bitPattern: 0), to: sqlite3_destructor_type.self)\n"
  code += "      sqlite3_bind_blob(insert, \(primaryKeys.count + 1), memory, Int32(byteBuffer.size), SQLITE_STATIC)\n"
  code += "      guard SQLITE_DONE == sqlite3_step(insert) else { return nil }\n"
  code += "      _rowid = sqlite3_last_insert_rowid(toolbox.connection.sqlite)\n"
  for (i, indexedField) in indexedFields.enumerated() {
    code += "      if indexSurvey.full.contains(\"\(indexedField.keyName)\") {\n"
    code += "        guard let i\(i) = toolbox.connection.prepareStatement(\"INSERT INTO \(tableName)__\(indexedField.keyName) (rowid, \(indexedField.keyName)) VALUES (?1, ?2)\") else { return nil }\n"
    code += "        _rowid.bindSQLite(i\(i), parameterId: 1)\n"
    code += "        let r\(i) = \(GetIndexedFieldExpr(structDef, indexedField: indexedField)).evaluate(object: .object(atom))\n"
    code += "        if r\(i).unknown {\n"
    code += "          sqlite3_bind_null(i\(i), 2)\n"
    code += "        } else {\n"
    code += "          r\(i).result.bindSQLite(i\(i), parameterId: 2)\n"
    code += "        }\n"
    code += "        guard SQLITE_DONE == sqlite3_step(i\(i)) else { return nil }\n"
    code += "      }\n"
  }
  code += "      _type = .none\n"
  code += "      atom._rowid = _rowid\n"
  code += "      return .inserted(atom)\n"
  code += "    case .update:\n"
  code += "      guard let update = toolbox.connection.prepareStatement(\"UPDATE \(tableName) SET \(primaryKeys.enumerated().map { "__pk\($0.offset)=?\($0.offset + 1)" }.joined(separator: ", ")), p=?\(primaryKeys.count + 1) WHERE rowid=?\(primaryKeys.count + 2) LIMIT 1\") else { return nil }\n"
  for (i, field) in primaryKeys.enumerated() {
    code += "      \(field.name).bindSQLite(update, parameterId: \(i + 1))\n"
  }
  code += "      let atom = self._atom\n"
  code += "      toolbox.flatBufferBuilder.clear()\n"
  code += "      let offset = atom.to(flatBufferBuilder: &toolbox.flatBufferBuilder)\n"
  code += "      toolbox.flatBufferBuilder.finish(offset: offset)\n"
  code += "      let byteBuffer = toolbox.flatBufferBuilder.buffer\n"
  code += "      let memory = byteBuffer.memory.advanced(by: byteBuffer.reader)\n"
  code += "      let SQLITE_STATIC = unsafeBitCast(OpaquePointer(bitPattern: 0), to: sqlite3_destructor_type.self)\n"
  code += "      sqlite3_bind_blob(update, \(primaryKeys.count + 1), memory, Int32(byteBuffer.size), SQLITE_STATIC)\n"
  code += "      _rowid.bindSQLite(update, parameterId: \(primaryKeys.count + 2))\n"
  code += "      guard SQLITE_DONE == sqlite3_step(update) else { return nil }\n"
  for (i, indexedField) in indexedFields.enumerated() {
    code += "      if indexSurvey.full.contains(\"\(indexedField.keyName)\") {\n"
    code += "        guard let u\(i) = toolbox.connection.prepareStatement(\"UPDATE \(tableName)__\(indexedField.keyName) SET \(indexedField.keyName)=?1 WHERE rowid=?2 LIMIT 1\") else { return nil }\n"
    code += "        _rowid.bindSQLite(u\(i), parameterId: 2)\n"
    code += "        let r\(i) = \(GetIndexedFieldExpr(structDef, indexedField: indexedField)).evaluate(object: .object(atom))\n"
    code += "        if r\(i).unknown {\n"
    code += "          sqlite3_bind_null(u\(i), 1)\n"
    code += "        } else {\n"
    code += "          r\(i).result.bindSQLite(u\(i), parameterId: 1)\n"
    code += "        }\n"
    code += "        guard SQLITE_DONE == sqlite3_step(u\(i)) else { return nil }\n"
    code += "      }\n"
  }
  code += "      _type = .none\n"
  code += "      return .updated(atom)\n"
  code += "    case .deletion:\n"
  code += "      guard let deletion = toolbox.connection.prepareStatement(\"DELETE FROM \(tableName) WHERE rowid=?1\") else { return nil }\n"
  code += "      _rowid.bindSQLite(deletion, parameterId: 1)\n"
  code += "      guard SQLITE_DONE == sqlite3_step(deletion) else { return nil }\n"
  for (i, indexedField) in indexedFields.enumerated() {
    code += "      if let d\(i) = toolbox.connection.prepareStatement(\"DELETE FROM \(tableName)__\(indexedField.keyName) WHERE rowid=?1\") {\n"
    code += "        _rowid.bindSQLite(d\(i), parameterId: 1)\n"
    code += "        sqlite3_step(d\(i))\n"
    code += "      }\n"
  }
  code += "      _type = .none\n"
  code += "      return .deleted(_rowid)\n"
  code += "    case .none:\n"
  code += "      preconditionFailure()\n"
  code += "    }\n"
  code += "  }\n"
  code += "}\n"
  if structDef.namespace.count > 0 {
    code += "\n}\n"
    code += "\n// MARK - \(structDef.namespace.joined(separator: "."))\n"
  }
}

func GenMutating(schema: Schema, outputPath: String) {
  var code = "import Dflat\nimport SQLiteDflat\nimport SQLite3\nimport FlatBuffers\n\n"
  code += "// MARK - SQLiteValue for Enumerations\n"
  for enumDef in schema.enums {
    guard !enumDef.isUnion else { continue }
    GenEnumSQLiteValue(enumDef, code: &code)
  }
  code += "\n// MARK - Serializer\n"
  for enumDef in schema.enums {
    guard enumDef.isUnion else { continue }
    GenUnionSerializer(enumDef, code: &code)
  }
  for structDef in schema.structs {
    guard structDef.name != schema.root else { continue }
    GenStructSerializer(structDef, code: &code)
  }
  for structDef in schema.structs {
    guard !structDef.fixed else { continue }
    if structDef.name == schema.root {
      GenStructSerializer(structDef, code: &code)
      break
    }
  }
  code += "\n// MARK - ChangeRequest\n"
  for structDef in schema.structs {
    guard !structDef.fixed else { continue }
    if structDef.name == schema.root {
      GenChangeRequest(structDef, code: &code)
      break
    }
  }
  try! code.write(to: URL(fileURLWithPath: outputPath), atomically: false, encoding: String.Encoding.utf8)
}

func GenQueryForField(_ structDef: Struct, keyPaths: [KeyPath], field: Field, pkCount: inout Int, code: inout String, addon: inout String) {
  let key = GetKeyName(keyPaths: keyPaths, field: field, pkCount: &pkCount)
  let expandedName = GetExpandedName(keyPaths: keyPaths, field: field)
  let structProtocolName: String
  if structDef.namespace.count > 0 {
    structProtocolName = structDef.namespace.joined(separator: "__") + "__" + structDef.name
  } else {
    structProtocolName = structDef.name
  }
  switch field.type.type {
  case .union:
    let unionDef = enumDefs[field.type.union!]!
    code += "\n  struct \(field.name) {\n"
    code += "\n  public static func match<T: \(structProtocolName)__\(expandedName)>(_ ofType: T.Type) -> EqualToExpr<FieldExpr<Int32>, ValueExpr<Int32>> {\n"
    code += "    return ofType.match__\(structDef.name)__\(expandedName)\n"
    code += "  }\n"
    code += "  public static func `as`<T: \(structProtocolName)__\(expandedName)>(_ ofType: T.Type) -> T.AsType__\(structDef.name)__\(expandedName).Type {\n"
    code += "    return ofType.AsType__\(structDef.name)__\(expandedName).self\n"
    code += "  }\n"
    code += "\n  static private func _tr__\(expandedName)__type(_ table: ByteBuffer) -> (result: Int32, unknown: Bool) {\n"
    code += "    let tr0 = \(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).getRootAs\(structDef.name)(bb: table)\n"
    code += GetTraverseKeyFlatBuffers(keyPaths, defaultValue: "-1")
    code += "    return (Int32(tr\(keyPaths.count).\(field.name)Type.rawValue), false)\n"
    code += "  }\n"
    code += "\n  static private func _or__\(expandedName)__type(_ object: Dflat.Atom) -> (result: Int32, unknown: Bool) {\n"
    code += "    let or0 = object as! \(GetFullyQualifiedName(structDef))\n"
    code += GetTraverseKeyDflat(keyPaths, defaultValue: "-1")
    code += "    guard let o = or\(keyPaths.count).\(field.name) else { return (-1, true) }\n"
    code += "    switch o {\n"
    for enumVal in unionDef.fields {
      guard enumVal.name != "NONE" else { continue }
      code += "    case .\(enumVal.name.firstLowercased()):\n"
      code += "      return (\(enumVal.value), false)\n"
    }
    code += "    }\n"
    code += "  }\n"
    code += "  public static let _type: FieldExpr<Int32> = FieldExpr(name: \"\(expandedName)__type\", primaryKey: \(field.isPrimary ? "true" : "false"), hasIndex: \(field.hasIndex ? "true" : "false"), tableReader: _tr__\(expandedName)__type, objectReader: _or__\(expandedName)__type)\n"
    code += "\n  }\n"
    addon += "\npublic protocol \(structProtocolName)__\(expandedName) {\n"
    addon += "  associatedtype AsType__\(structDef.name)__\(expandedName)\n"
    addon += "  static var match__\(structDef.name)__\(expandedName): EqualToExpr<FieldExpr<Int32>, ValueExpr<Int32>> { get }\n"
    addon += "}\n"
    for enumVal in unionDef.fields {
      guard enumVal.name != "NONE" else { continue }
      let newKeyPaths = keyPaths + [KeyPath.union(field, enumVal)]
      let subStructDef = structDefs[enumVal.struct!]!
      var newAddon = ""
      addon += "\nextension \(GetFullyQualifiedName(subStructDef)): \(structProtocolName)__\(expandedName) {\n"
      addon += "  public static let match__\(structDef.name)__\(expandedName): EqualToExpr<FieldExpr<Int32>, ValueExpr<Int32>> = (\(GetFullyQualifiedName(structDef)).\(GetKeyPathQuery(keyPaths, field: field))._type == \(enumVal.value))\n"
      addon += "\n  public struct _\(expandedName)__\(subStructDef.name) {\n"
      for field in subStructDef.fields {
        guard IsDataField(field) else { continue }
        GenQueryForField(structDef, keyPaths: newKeyPaths, field: field, pkCount: &pkCount, code: &addon, addon: &newAddon)
      }
      addon += "  }\n"
      addon += "  public typealias AsType__\(structDef.name)__\(expandedName) = _\(expandedName)__\(subStructDef.name)\n"
      addon += "\n}\n"
      addon += newAddon
    }
  case .struct:
    code += "\n  struct \(field.name) {\n"
    let subStructDef = structDefs[field.type.struct!]!
    let newKeyPaths = keyPaths + [KeyPath.field(field)]
    for field in subStructDef.fields {
      guard IsDataField(field) else { continue }
      GenQueryForField(structDef, keyPaths: newKeyPaths, field: field, pkCount: &pkCount, code: &code, addon: &addon)
    }
    code += "\n  }\n"
  case .vector: // We cannot query vector, skip.
    break
  case .string:
    code += "\n  static private func _tr__\(expandedName)(_ table: ByteBuffer) -> (result: String, unknown: Bool) {\n"
    code += "    let tr0 = \(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).getRootAs\(structDef.name)(bb: table)\n"
    code += GetTraverseKeyFlatBuffers(keyPaths, defaultValue: "\"\"")
    if !field.isPrimary {
      code += "    guard let s = tr\(keyPaths.count).\(field.name) else { return (\"\", true) }\n"
      code += "    return (s, false)\n"
    } else {
      code += "    return (tr\(keyPaths.count).\(field.name)!, false)\n"
    }
    code += "  }\n"
    code += "  static private func _or__\(expandedName)(_ object: Dflat.Atom) -> (result: String, unknown: Bool) {\n"
    code += "    let or0 = object as! \(GetFullyQualifiedName(structDef))\n"
    code += GetTraverseKeyDflat(keyPaths, defaultValue: "\"\"")
    if !field.isPrimary {
      code += "    guard let s = or\(keyPaths.count).\(field.name) else { return (\"\", true) }\n"
      code += "    return (s, false)\n"
    } else {
      code += "    return (or\(keyPaths.count).\(field.name), false)\n"
    }
    code += "  }\n"
    if keyPaths.count > 0 {
      code += "  public "
    } else {
      code += "  "
    }
    code += "static let \(field.name): FieldExpr<String> = FieldExpr(name: \"\(key)\", primaryKey: \(field.isPrimary ? "true" : "false"), hasIndex: \(field.hasIndex ? "true" : "false"), tableReader: _tr__\(expandedName), objectReader: _or__\(expandedName))\n"
  case .enum:
    let enumDef = enumDefs[field.type.enum!]!
    code += "\n  static private func _tr__\(expandedName)(_ table: ByteBuffer) -> (result: \(GetFullyQualifiedName(enumDef)), unknown: Bool) {\n"
    code += "    let tr0 = \(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).getRootAs\(structDef.name)(bb: table)\n"
    code += GetTraverseKeyFlatBuffers(keyPaths, defaultValue: GetFieldDefaultValue(field, required: true))
    code += "    return (\(GetFullyQualifiedName(enumDef))(rawValue: tr\(keyPaths.count).\(field.name).rawValue)!, false)\n"
    code += "  }\n"
    code += "  static private func _or__\(expandedName)(_ object: Dflat.Atom) -> (result: \(GetFullyQualifiedName(enumDef)), unknown: Bool) {\n"
    code += "    let or0 = object as! \(GetFullyQualifiedName(structDef))\n"
    code += GetTraverseKeyDflat(keyPaths, defaultValue: GetFieldDefaultValue(field, required: true))
    code += "    return (or\(keyPaths.count).\(field.name), false)\n"
    code += "  }\n"
    if keyPaths.count > 0 {
      code += "  public "
    } else {
      code += "  "
    }
    code += "static let \(field.name): FieldExpr<\(GetFullyQualifiedName(enumDef))> = FieldExpr(name: \"\(key)\", primaryKey: \(field.isPrimary ? "true" : "false"), hasIndex: \(field.hasIndex ? "true" : "false"), tableReader: _tr__\(expandedName), objectReader: _or__\(expandedName))\n"
  default: // These are the simple types (string, scalar) or enum
    let swiftType = SwiftType[field.type.type.rawValue]!
    code += "\n  static private func _tr__\(expandedName)(_ table: ByteBuffer) -> (result: \(swiftType), unknown: Bool) {\n"
    code += "    let tr0 = \(DflatGenNamespace).\(GetFullyQualifiedName(structDef)).getRootAs\(structDef.name)(bb: table)\n"
    code += GetTraverseKeyFlatBuffers(keyPaths, defaultValue: GetFieldDefaultValue(field, required: true))
    code += "    return (tr\(keyPaths.count).\(field.name), false)\n"
    code += "  }\n"
    code += "  static private func _or__\(expandedName)(_ object: Dflat.Atom) -> (result: \(swiftType), unknown: Bool) {\n"
    code += "    let or0 = object as! \(GetFullyQualifiedName(structDef))\n"
    code += GetTraverseKeyDflat(keyPaths, defaultValue: GetFieldDefaultValue(field, required: true))
    code += "    return (or\(keyPaths.count).\(field.name), false)\n"
    code += "  }\n"
    if keyPaths.count > 0 {
      code += "  public "
    } else {
      code += "  "
    }
    code += "static let \(field.name): FieldExpr<\(swiftType)> = FieldExpr(name: \"\(key)\", primaryKey: \(field.isPrimary ? "true" : "false"), hasIndex: \(field.hasIndex ? "true" : "false"), tableReader: _tr__\(expandedName), objectReader: _or__\(expandedName))\n"
  }
}

func GenQueryRoot(_ structDef: Struct, code: inout String) {
  code += "\nextension \(GetFullyQualifiedName(structDef)) {\n"
  var addon = ""
  var pkCount = 0
  for field in structDef.fields {
    guard IsDataField(field) else { continue }
    GenQueryForField(structDef, keyPaths: [], field: field, pkCount: &pkCount, code: &code, addon: &addon)
  }
  code += "}\n"
  code += addon
}

func GenQuery(schema: Schema, outputPath: String) {
  var code = "import Dflat\nimport FlatBuffers\n"
  for structDef in schema.structs {
    guard !structDef.fixed else { continue }
    if structDef.name == schema.root {
      GenQueryRoot(structDef, code: &code)
      break
    }
  }
  try! code.write(to: URL(fileURLWithPath: outputPath), atomically: false, encoding: String.Encoding.utf8)
}

func GenSwift(_ filePath: String, _ outputPath: String) {
  let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  let schema = try! decoder.decode(Schema.self, from: data)
  for enumDef in schema.enums {
    enumDefs[enumDef.name] = enumDef
  }
  for structDef in schema.structs {
    structDefs[structDef.name] = structDef
  }
  let fileComponents = filePath.split(separator: "/")
  let filename = fileComponents.last!
  let filebase = filename.prefix(filename.count - "_generated.json".count)
  let rootStructDef = structDefs[schema.root]!
  DflatGenNamespace = (["DflatGen"] + rootStructDef.namespace).joined(separator: "__")
  GenDataModel(schema: schema, outputPath: outputPath + "/" + filebase + "_data_model_generated.swift")
  GenMutating(schema: schema, outputPath: outputPath + "/" + filebase + "_mutating_generated.swift")
  GenQuery(schema: schema, outputPath: outputPath + "/" + filebase + "_query_generated.swift")
}

var outputPath: String? = nil
var argi = 1
var filePaths = [String]()
while argi < CommandLine.arguments.count {
  let argument = CommandLine.arguments[argi]
  if argument == "-o" {
    argi += 1
    if argi >= CommandLine.arguments.count {
      fatalError("missing path following -o")
    }
    outputPath = CommandLine.arguments[argi]
  } else {
    filePaths.append(argument)
  }
  argi += 1
}
guard let outputPath = outputPath else { fatalError("no output path specified") }
for filePath in filePaths {
  GenSwift(filePath, outputPath)
}
