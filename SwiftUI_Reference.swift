import SwiftUI

struct AlignmentTestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("HStack and VStack Alignment Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 32)
                
                // HStack Tests
                VStack(alignment: .leading, spacing: 24) {
                    Text("HStack Alignment Tests")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    hstackAlignmentTests
                }
                
                // VStack Tests
                VStack(alignment: .leading, spacing: 24) {
                    Text("VStack Alignment Tests")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    vstackAlignmentTests
                }
                
                // Complex nested tests
                VStack(alignment: .leading, spacing: 24) {
                    Text("Complex Nested Alignment Tests")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    complexNestedTests
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    private var hstackAlignmentTests: some View {
        VStack(spacing: 24) {
            // HStack with top alignment
            TestContainer(title: "HStack - Top Alignment") {
                HStack(alignment: .top, spacing: 16) {
                    ColoredBox(label: "Small", color: .blue, height: 40)
                    ColoredBox(label: "Medium", color: .green, height: 80)
                    ColoredBox(label: "Large", color: .red, height: 120)
                }
            }
            
            // HStack with center alignment (default)
            TestContainer(title: "HStack - Center Alignment") {
                HStack(alignment: .center, spacing: 16) {
                    ColoredBox(label: "Small", color: .blue, height: 40)
                    ColoredBox(label: "Medium", color: .green, height: 80)
                    ColoredBox(label: "Large", color: .red, height: 120)
                }
            }
            
            // HStack with bottom alignment
            TestContainer(title: "HStack - Bottom Alignment") {
                HStack(alignment: .bottom, spacing: 16) {
                    ColoredBox(label: "Small", color: .blue, height: 40)
                    ColoredBox(label: "Medium", color: .green, height: 80)
                    ColoredBox(label: "Large", color: .red, height: 120)
                }
            }
            
            // HStack with different distributions
            TestContainer(title: "HStack - Leading") {
                HStack(spacing: 16) {
                    ColoredBox(label: "1", color: .purple)
                    ColoredBox(label: "2", color: .yellow)
                    ColoredBox(label: "3", color: .pink)
                    Spacer()
                }
            }
            
            TestContainer(title: "HStack - Center") {
                HStack(spacing: 16) {
                    Spacer()
                    ColoredBox(label: "1", color: .purple)
                    ColoredBox(label: "2", color: .yellow)
                    ColoredBox(label: "3", color: .pink)
                    Spacer()
                }
            }
            
            TestContainer(title: "HStack - Trailing") {
                HStack(spacing: 16) {
                    Spacer()
                    ColoredBox(label: "1", color: .purple)
                    ColoredBox(label: "2", color: .yellow)
                    ColoredBox(label: "3", color: .pink)
                }
            }
            
            TestContainer(title: "HStack - Space Between") {
                HStack {
                    ColoredBox(label: "1", color: .purple)
                    Spacer()
                    ColoredBox(label: "2", color: .yellow)
                    Spacer()
                    ColoredBox(label: "3", color: .pink)
                }
            }
            
            TestContainer(title: "HStack - Equal Spacing") {
                HStack(spacing: 0) {
                    ColoredBox(label: "1", color: .purple)
                    Spacer()
                    ColoredBox(label: "2", color: .yellow)
                    Spacer()
                    ColoredBox(label: "3", color: .pink)
                }
            }
        }
    }
    
    private var vstackAlignmentTests: some View {
        HStack(spacing: 32) {
            // VStack with leading alignment
            TestContainer(title: "VStack - Leading Alignment") {
                VStack(alignment: .leading, spacing: 16) {
                    ColoredBox(label: "Short", color: .blue, width: 60)
                    ColoredBox(label: "Medium Width", color: .green, width: 120)
                    ColoredBox(label: "Very Long Width", color: .red, width: 180)
                }
            }
            
            // VStack with center alignment (default)
            TestContainer(title: "VStack - Center Alignment") {
                VStack(alignment: .center, spacing: 16) {
                    ColoredBox(label: "Short", color: .blue, width: 60)
                    ColoredBox(label: "Medium Width", color: .green, width: 120)
                    ColoredBox(label: "Very Long Width", color: .red, width: 180)
                }
            }
            
            // VStack with trailing alignment
            TestContainer(title: "VStack - Trailing Alignment") {
                VStack(alignment: .trailing, spacing: 16) {
                    ColoredBox(label: "Short", color: .blue, width: 60)
                    ColoredBox(label: "Medium Width", color: .green, width: 120)
                    ColoredBox(label: "Very Long Width", color: .red, width: 180)
                }
            }
        }
    }
    
    private var complexNestedTests: some View {
        VStack(spacing: 32) {
            // Complex nested alignment - Card-like layouts
            TestContainer(title: "Complex Card Layout") {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with space between
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
                        ColoredBox(label: "Badge", color: .green, width: 60, height: 24)
                    }
                    
                    // Content area
                    HStack(alignment: .top, spacing: 16) {
                        ColoredBox(label: "Image", color: .blue, width: 80, height: 80)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description text that wraps")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text("Additional details")
                                .font(.caption)
                                .foregroundColor(.tertiary)
                        }
                        Spacer()
                    }
                    
                    // Footer with actions
                    HStack {
                        Spacer()
                        ColoredBox(label: "Cancel", color: .gray, width: 60, height: 32)
                        ColoredBox(label: "Save", color: .blue, width: 60, height: 32)
                    }
                }
            }
            
            // Dashboard-style layout
            TestContainer(title: "Dashboard Layout") {
                VStack(spacing: 24) {
                    // Top metrics row
                    HStack {
                        MetricCard(label: "Users", value: "1,234", color: .green)
                        Spacer()
                        MetricCard(label: "Revenue", value: "$56,789", color: .blue)
                        Spacer()
                        MetricCard(label: "Orders", value: "890", color: .purple)
                    }
                    
                    // Content area with sidebar
                    HStack(alignment: .top, spacing: 24) {
                        // Sidebar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Navigation")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 8)
                            
                            NavItem(label: "Dashboard", isActive: true)
                            NavItem(label: "Users", isActive: false)
                            NavItem(label: "Settings", isActive: false)
                        }
                        .frame(width: 120)
                        
                        // Main content
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Main Content")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                ColoredBox(label: "Action", color: .blue, width: 80, height: 32)
                            }
                            
                            ColoredBox(label: "Content Area", color: .gray, width: 400, height: 200)
                        }
                    }
                }
            }
        }
    }
}

struct TestContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
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
        .shadow(radius: 2)
    }
}

struct ColoredBox: View {
    let label: String
    let color: Color
    let width: CGFloat
    let height: CGFloat
    
    init(label: String, color: Color, width: CGFloat = 80, height: CGFloat = 60) {
        self.label = label
        self.color = color
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Text(label)
            .foregroundColor(.white)
            .fontWeight(.medium)
            .frame(width: width, height: height)
            .background(color)
            .cornerRadius(8)
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct NavItem: View {
    let label: String
    let isActive: Bool
    
    var body: some View {
        Text(label)
            .foregroundColor(isActive ? .blue : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
    }
}

struct AlignmentTestView_Previews: PreviewProvider {
    static var previews: some View {
        AlignmentTestView()
    }
}