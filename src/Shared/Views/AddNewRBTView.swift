//
//  AddNewRBTView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI

struct AddNewRBTView: View {
    
    @ObservedObject
    var viewModel: DayViewModel
    
    @StateObject
    private var promptsViewModel = PromptsViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Header
                headerView
                
                // Prompts Section
                PromptsView(viewModel: promptsViewModel) { selectedPrompt in
                    handlePromptSelection(selectedPrompt)
                }
                
                // Main Content
                mainContentView
                
                // Save Button
                saveButton
            }
            .padding(Spacing.medium)
        }
        .refreshable {
            await promptsViewModel.refreshPrompts()
        }
        .background(DesignTokens.primaryBackground)
        .promptsAuthorizationAlert(
            isPresented: $promptsViewModel.showAuthorizationAlert
        ) {
            await promptsViewModel.handleAuthorizationAlert()
        }
        .onAppear {
            self.viewModel.load()
            Task {
                await promptsViewModel.loadPromptsIfNeeded()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack(spacing: Spacing.medium) {
            Text("Add New RBT")
                .font(.rbtTitle2)
                .foregroundColor(DesignTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            Text(viewModel.dateString())
                .font(.rbtSubheadline)
                .foregroundColor(DesignTokens.secondaryText)
            
            Spacer()
            
            Button("Dismiss") {
                presentationMode.wrappedValue.dismiss()
            }
            .accessibleTouchTarget(label: "Dismiss", hint: "Close this screen without saving")
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: Spacing.large) {
            ItemView(model: self.viewModel.model!.rose)
                .frame(minWidth: 0, maxWidth: .infinity)
            
            ItemView(model: self.viewModel.model!.bud)
                .frame(minWidth: 0, maxWidth: .infinity)
            
            ItemView(model: self.viewModel.model!.thorn)
                .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            viewModel.save()
        }
        .accessibleTouchTarget(label: "Save", hint: "Save your Rose, Bud, and Thorn entries")
        .frame(height: DesignTokens.buttonHeight)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.accentColor)
        .foregroundColor(DesignTokens.primaryBackground)
        .cornerRadius(DesignTokens.cornerRadiusMedium)
    }
    
    // MARK: - Actions
    
    private func handlePromptSelection(_ prompt: String) {
        // Find the first empty note field and pre-fill it with the selected prompt
        if viewModel.model!.rose.note.isEmpty {
            viewModel.model!.rose.note = prompt
        } else if viewModel.model!.bud.note.isEmpty {
            viewModel.model!.bud.note = prompt
        } else if viewModel.model!.thorn.note.isEmpty {
            viewModel.model!.thorn.note = prompt
        }
        // If all fields have content, replace the rose note as it's the primary positive reflection
        else {
            viewModel.model!.rose.note = prompt
        }
        
        // Trigger UI update by calling objectWillChange
        viewModel.objectWillChange.send()
    }
}

struct AddNewRBTView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewRBTView(viewModel: DayViewModel(date: Date()))
    }
}
