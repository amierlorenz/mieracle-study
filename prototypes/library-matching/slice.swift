// PROTOTYPE — throwaway. Usage: swift slice.swift <in.pdf> <first> <last> <out.pdf>
import PDFKit
let a = CommandLine.arguments
let src = PDFDocument(url: URL(fileURLWithPath: a[1]))!
let out = PDFDocument()
for (i, p) in (Int(a[2])!...Int(a[3])!).enumerated() { out.insert(src.page(at: p - 1)!, at: i) }
out.write(to: URL(fileURLWithPath: a[4]))
print("\(out.pageCount) pages")
