import SwiftUI
import PlaygroundSupport

struct AlignmentPlaygroundView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("HStack & VStack Alignment Permutations")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // MARK: - HStack Vertical Alignments
                Group {
                    SectionHeader("HStack Vertical Alignments")
                    
                    TestBox("HStack .top alignment") {
                        HStack(alignment: .top, spacing: 20) {
                            ColorBox("S", .blue, height: 40)
                            ColorBox("M", .green, height: 80)
                            ColorBox("L", .red, height: 120)
                            ColorBox("XL", .purple, height: 160)
                        }
                    }
                    
                    TestBox("HStack .center alignment (default)") {
                        HStack(alignment: .center, spacing: 20) {
                            ColorBox("S", .blue, height: 40)
                            ColorBox("M", .green, height: 80)
                            ColorBox("L", .red, height: 120)
                            ColorBox("XL", .purple, height: 160)
                        }
                    }
                    
                    TestBox("HStack .bottom alignment") {
                        HStack(alignment: .bottom, spacing: 20) {
                            ColorBox("S", .blue, height: 40)
                            ColorBox("M", .green, height: 80)
                            ColorBox("L", .red, height: 120)
                            ColorBox("XL", .purple, height: 160)
                        }
                    }
                    
                    TestBox("HStack .firstTextBaseline alignment") {
                        HStack(alignment: .firstTextBaseline, spacing: 20) {
                            Text("Small").font(.caption)
                            Text("Medium").font(.body)
                            Text("Large").font(.title)
                            Text("XL").font(.largeTitle)
                        }
                    }
                    
                    TestBox("HStack .lastTextBaseline alignment") {
                        HStack(alignment: .lastTextBaseline, spacing: 20) {
                            Text("Small").font(.caption)
                            Text("Medium").font(.body)
                            Text("Large").font(.title)
                            Text("XL").font(.largeTitle)
                        }
                    }
                }
                
                // MARK: - VStack Horizontal Alignments
                Group {
                    SectionHeader("VStack Horizontal Alignments")
                    
                    HStack(spacing: 40) {
                        TestBox("VStack .leading alignment") {
                            VStack(alignment: .leading, spacing: 20) {
                                ColorBox("Short", .blue, width: 60)
                                ColorBox("Medium Text", .green, width: 120)
                                ColorBox("Very Long Text", .red, width: 180)
                                ColorBox("Extra Long Content", .purple, width: 200)
                            }
                        }
                        
                        TestBox("VStack .center alignment (default)") {
                            VStack(alignment: .center, spacing: 20) {
                                ColorBox("Short", .blue, width: 60)
                                ColorBox("Medium Text", .green, width: 120)
                                ColorBox("Very Long Text", .red, width: 180)
                                ColorBox("Extra Long Content", .purple, width: 200)
                            }
                        }
                        
                        TestBox("VStack .trailing alignment") {
                            VStack(alignment: .trailing, spacing: 20) {
                                ColorBox("Short", .blue, width: 60)
                                ColorBox("Medium Text", .green, width: 120)
                                ColorBox("Very Long Text", .red, width: 180)
                                ColorBox("Extra Long Content", .purple, width: 200)
                            }
                        }
                    }
                }
                
                // MARK: - HStack with Spacers (Distribution)
                Group {
                    SectionHeader("HStack Distribution with Spacers")
                    
                    TestBox("Leading (no spacers)") {
                        HStack(spacing: 20) {
                            ColorBox("1", .blue)
                            ColorBox("2", .green)
                            ColorBox("3", .red)
                            // No spacer = leading alignment
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    TestBox("Trailing (trailing spacer)") {
                        HStack(spacing: 20) {
                            Spacer()
                            ColorBox("1", .blue)
                            ColorBox("2", .green)
                            ColorBox("3", .red)
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    TestBox("Center (leading + trailing spacers)") {
                        HStack(spacing: 20) {
                            Spacer()
                            ColorBox("1", .blue)
                            ColorBox("2", .green)
                            ColorBox("3", .red)
                            Spacer()
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    TestBox("Space Between (spacers between items)") {
                        HStack(spacing: 0) {
                            ColorBox("1", .blue)
                            Spacer()
                            ColorBox("2", .green)
                            Spacer()
                            ColorBox("3", .red)
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    TestBox("Space Around (spacers around all items)") {
                        HStack(spacing: 0) {
                            Spacer()
                            ColorBox("1", .blue)
                            Spacer()
                            ColorBox("2", .green)
                            Spacer()
                            ColorBox("3", .red)
                            Spacer()
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    TestBox("Space Evenly (equal spacers)") {
                        HStack(spacing: 0) {
                            Spacer()
                            ColorBox("1", .blue)
                            Spacer()
                            ColorBox("2", .green)
                            Spacer()
                            ColorBox("3", .red)
                            Spacer()
                        }
                        .frame(width: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                }
                
                // MARK: - VStack with Spacers (Distribution)
                Group {
                    SectionHeader("VStack Distribution with Spacers")
                    
                    HStack(spacing: 40) {
                        TestBox("Top (no spacers)") {
                            VStack(spacing: 20) {
                                ColorBox("1", .blue)
                                ColorBox("2", .green)
                                ColorBox("3", .red)
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                        
                        TestBox("Bottom (top spacer)") {
                            VStack(spacing: 20) {
                                Spacer()
                                ColorBox("1", .blue)
                                ColorBox("2", .green)
                                ColorBox("3", .red)
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                        
                        TestBox("Center (top + bottom spacers)") {
                            VStack(spacing: 20) {
                                Spacer()
                                ColorBox("1", .blue)
                                ColorBox("2", .green)
                                ColorBox("3", .red)
                                Spacer()
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                    }
                    
                    HStack(spacing: 40) {
                        TestBox("Space Between") {
                            VStack(spacing: 0) {
                                ColorBox("1", .blue)
                                Spacer()
                                ColorBox("2", .green)
                                Spacer()
                                ColorBox("3", .red)
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                        
                        TestBox("Space Around") {
                            VStack(spacing: 0) {
                                Spacer()
                                ColorBox("1", .blue)
                                Spacer()
                                ColorBox("2", .green)
                                Spacer()
                                ColorBox("3", .red)
                                Spacer()
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                        
                        TestBox("Space Evenly") {
                            VStack(spacing: 0) {
                                Spacer()
                                ColorBox("1", .blue)
                                Spacer()
                                ColorBox("2", .green)
                                Spacer()
                                ColorBox("3", .red)
                                Spacer()
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                        }
                    }
                }
                
                // MARK: - Complex Nested Alignments
                Group {
                    SectionHeader("Complex Nested Alignments")
                    
                    TestBox("Card Layout - Mixed Alignments") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header - space between
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Card Title")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("Subtitle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                ColorBox("Badge", .green, width: 50, height: 20)
                            }
                            
                            // Content - top aligned
                            HStack(alignment: .top, spacing: 16) {
                                ColorBox("IMG", .blue, width: 60, height: 60)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description content")
                                        .font(.body)
                                    Text("Additional details")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            // Footer - trailing aligned
                            HStack {
                                Spacer()
                                ColorBox("Cancel", .gray, width: 60, height: 30)
                                ColorBox("Save", .blue, width: 60, height: 30)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    TestBox("Dashboard Layout") {
                        VStack(spacing: 24) {
                            // Metrics row - space around
                            HStack(spacing: 0) {
                                Spacer()
                                MetricCard("Users", "1,234", .green)
                                Spacer()
                                MetricCard("Revenue", "$56K", .blue)
                                Spacer()
                                MetricCard("Orders", "890", .purple)
                                Spacer()
                            }
                            
                            // Main content - top aligned
                            HStack(alignment: .top, spacing: 24) {
                                // Sidebar - leading aligned
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Navigation")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    NavItem("Dashboard", true)
                                    NavItem("Users", false)
                                    NavItem("Settings", false)
                                }
                                .frame(width: 120)
                                
                                // Content - leading aligned
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Main Content")
                                            .font(.headline)
                                        Spacer()
                                        ColorBox("Action", .blue, width: 70, height: 30)
                                    }
                                    ColorBox("Content", .gray, width: 300, height: 150)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Alignment Guides (Advanced)
                Group {
                    SectionHeader("Custom Alignment Guides")
                    
                    TestBox("Custom Alignment Guide") {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Label:")
                                    .font(.caption)
                                    .alignmentGuide(.leading) { d in d[.trailing] }
                                Text("Value")
                                    .font(.body)
                            }
                            HStack {
                                Text("Longer Label:")
                                    .font(.caption)
                                    .alignmentGuide(.leading) { d in d[.trailing] }
                                Text("Another Value")
                                    .font(.body)
                            }
                            HStack {
                                Text("Short:")
                                    .font(.caption)
                                    .alignmentGuide(.leading) { d in d[.trailing] }
                                Text("Third Value")
                                    .font(.body)
                            }
                        }
                    }
                }
                
                // MARK: - All Combinations Matrix
                Group {
                    SectionHeader("All Combinations Matrix")
                    
                    VStack(spacing: 16) {
                        Text("HStack alignments × VStack alignments")
                            .font(.headline)
                        
                        // Matrix of all combinations
                        VStack(spacing: 12) {
                            ForEach(VAlignment.allCases, id: \.self) { vAlign in
                                HStack(spacing: 12) {
                                    Text("\(vAlign.rawValue)")
                                        .font(.caption)
                                        .frame(width: 80)
                                    
                                    ForEach(HAlignment.allCases, id: \.self) { hAlign in
                                        VStack(alignment: hAlign.alignment, spacing: 4) {
                                            HStack(alignment: vAlign.alignment, spacing: 4) {
                                                ColorBox("1", .blue, width: 20, height: 20)
                                                ColorBox("2", .red, width: 20, height: 30)
                                            }
                                            Text("\(hAlign.rawValue)")
                                                .font(.caption2)
                                        }
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.top, 20)
    }
}

struct TestBox<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            content
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ColorBox: View {
    let text: String
    let color: Color
    let width: CGFloat
    let height: CGFloat
    
    init(_ text: String, _ color: Color, width: CGFloat = 60, height: CGFloat = 60) {
        self.text = text
        self.color = color
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .background(color)
            .cornerRadius(8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    init(_ title: String, _ value: String, _ color: Color) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct NavItem: View {
    let title: String
    let isActive: Bool
    
    init(_ title: String, _ isActive: Bool) {
        self.title = title
        self.isActive = isActive
    }
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(isActive ? .blue : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
    }
}

// MARK: - Enums for Matrix
enum VAlignment: String, CaseIterable {
    case top, center, bottom, firstTextBaseline, lastTextBaseline
    
    var alignment: VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        case .firstTextBaseline: return .firstTextBaseline
        case .lastTextBaseline: return .lastTextBaseline
        }
    }
}

enum HAlignment: String, CaseIterable {
    case leading, center, trailing
    
    var alignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - Playground Setup
PlaygroundPage.current.setLiveView(AlignmentPlaygroundView())