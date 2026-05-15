import AppIntents

/// Typed enum that lets Siri / Shortcuts understand expense category names.
enum ExpenseCategoryAppEnum: String, AppEnum {
    case food           = "Food"
    case transport      = "Transport"
    case shopping       = "Shopping"
    case health         = "Health"
    case entertainment  = "Entertainment"
    case bills          = "Bills"
    case other          = "Other"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Expense Category")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .food:          DisplayRepresentation(title: "Food",          image: .init(systemName: "fork.knife")),
            .transport:     DisplayRepresentation(title: "Transport",     image: .init(systemName: "car.fill")),
            .shopping:      DisplayRepresentation(title: "Shopping",      image: .init(systemName: "bag.fill")),
            .health:        DisplayRepresentation(title: "Health",        image: .init(systemName: "heart.fill")),
            .entertainment: DisplayRepresentation(title: "Entertainment", image: .init(systemName: "popcorn.fill")),
            .bills:         DisplayRepresentation(title: "Bills",         image: .init(systemName: "doc.text.fill")),
            .other:         DisplayRepresentation(title: "Other",         image: .init(systemName: "ellipsis.circle.fill")),
        ]
    }
}
