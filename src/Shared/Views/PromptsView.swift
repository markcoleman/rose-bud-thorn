//
//  PromptsView.swift
//  rose.bud.thorn
//
//  Created by Copilot for JournalKit prompts integration
//

import SwiftUI

/// View component for displaying reflection prompts with proper accessibility
struct PromptsView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PromptsViewModel
    let onPromptSelected: (String) -> Void
    
    // MARK: - Body
    
    var body: some View {
        if viewModel.authorizationStatus == .authorized && !viewModel.prompts.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Prompts Header
                Text("Prompts")
                    .font(.rbtHeadline)
                    .foregroundColor(DesignTokens.primaryText)
                    .accessibilityAddTraits(.isHeader)
                
                // Loading State
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Finding inspiration...")
                            .font(.rbtCaption)
                            .foregroundColor(DesignTokens.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading personalized prompts")
                }
                
                // Prompts List
                if !viewModel.isLoading && !viewModel.prompts.isEmpty {
                    VStack(spacing: Spacing.small) {
                        ForEach(Array(viewModel.prompts.enumerated()), id: \.offset) { index, prompt in
                            PromptButton(
                                prompt: prompt,
                                index: index + 1,
                                action: {
                                    onPromptSelected(prompt)
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Prompt Button Component

/// Individual prompt button with proper accessibility
private struct PromptButton: View {
    let prompt: String
    let index: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(prompt)
                    .font(.rbtBody)
                    .foregroundColor(DesignTokens.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right.circle")
                    .font(.rbtBody)
                    .foregroundColor(DesignTokens.secondaryText)
            }
            .padding(Spacing.medium)
            .background(DesignTokens.secondaryBackground)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
        }
        .accessibleTouchTarget(
            label: prompt,
            hint: "Tap to use this prompt for your reflection"
        )
        .accessibilityValue("Prompt \(index) of \(3)")
    }
}

// MARK: - Preview Provider

struct PromptsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode with prompts
            VStack {
                PromptsView(
                    viewModel: createMockViewModel(withPrompts: true),
                    onPromptSelected: { _ in }
                )
                Spacer()
            }
            .padding()
            .background(DesignTokens.primaryBackground)
            .previewDisplayName("Light Mode - With Prompts")
            
            // Dark mode with prompts
            VStack {
                PromptsView(
                    viewModel: createMockViewModel(withPrompts: true),
                    onPromptSelected: { _ in }
                )
                Spacer()
            }
            .padding()
            .background(DesignTokens.primaryBackground)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode - With Prompts")
            
            // Loading state
            VStack {
                PromptsView(
                    viewModel: createMockViewModel(loading: true),
                    onPromptSelected: { _ in }
                )
                Spacer()
            }
            .padding()
            .background(DesignTokens.primaryBackground)
            .previewDisplayName("Loading State")
        }
    }
    
    private static func createMockViewModel(withPrompts: Bool = false, loading: Bool = false) -> PromptsViewModel {
        let viewModel = PromptsViewModel()
        viewModel.authorizationStatus = .authorized
        
        if loading {
            viewModel.isLoading = true
        } else if withPrompts {
            viewModel.prompts = [
                "What made you smile today?",
                "Describe a moment when you felt grateful.",
                "What's one thing you learned about yourself recently?"
            ]
        }
        
        return viewModel
    }
}