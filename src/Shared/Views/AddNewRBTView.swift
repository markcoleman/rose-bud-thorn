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
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        VStack(spacing: Spacing.large){
            HStack(spacing: Spacing.medium){
                Text("Add New RBT")
                    .font(.rbtTitle2)
                    .foregroundColor(DesignTokens.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Text(viewModel.dateString())
                    .font(.rbtSubheadline)
                    .foregroundColor(DesignTokens.secondaryText)
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
                .accessibleTouchTarget(label: "Dismiss", hint: "Close this screen without saving")
            }
            ItemView(model: self.viewModel.model!.rose)
                .frame(minWidth:0, maxWidth: .infinity)
            ItemView(model: self.viewModel.model!.bud)
                .frame(minWidth:0, maxWidth: .infinity)
            ItemView(model: self.viewModel.model!.thorn)
                .frame(minWidth:0, maxWidth: .infinity)
            
            Button("Save"){
                viewModel.save()
            }
            .accessibleTouchTarget(label: "Save", hint: "Save your Rose, Bud, and Thorn entries")
            .frame(height: DesignTokens.buttonHeight)
            .background(DesignTokens.accentColor)
            .foregroundColor(DesignTokens.primaryBackground)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
        } .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(Spacing.medium)
        .background(DesignTokens.primaryBackground)
        .onAppear{
            self.viewModel.load()
        }
    }
}

struct AddNewRBTView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewRBTView(viewModel: DayViewModel(date: Date()))
    }
}
