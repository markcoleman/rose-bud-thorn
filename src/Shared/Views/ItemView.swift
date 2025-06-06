//
//  ItemView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/21/21.
//

import SwiftUI

struct ItemView: View {
    
    @ObservedObject
    var viewModel: ItemViewModel
    
    init(model: Item){
        viewModel = ItemViewModel(model: model)
    }
    
    @State var edit = false
    
    var body: some View {
        
        return VStack () {
                if(self.edit == true){
                    VStack(spacing: Spacing.medium){
                        Section(header: Text(self.viewModel.toTitle)
                                    .font(.rbtLargeTitle) )
                        {                            
                            TextField("Note", text: $viewModel.model.note)
                                .padding(Spacing.small)
                                .accessibilityLabel("Note for \(self.viewModel.toTitle)")
                            TextField("Media URL", text: $viewModel.model.mediaUrl)
                                .padding(Spacing.small)
                                .accessibilityLabel("Image URL for \(self.viewModel.toTitle)")
                        }.textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack(spacing: Spacing.medium){
                            Button(action:{
                                edit = false
                            }, label: {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                            })
                            .accessibleTouchTarget(label: "Cancel editing", hint: "Discard changes and return to view mode")
                            Button(action:{
                                edit = false
                                viewModel.save()
                            }, label: {
                                Label("Save", systemImage: "checkmark.circle.fill")
                            })
                            .accessibleTouchTarget(label: "Save changes", hint: "Save your edits and return to view mode")
                        }.padding(Spacing.small)
                    }
                }
                else{
                    ZStack(){
                        Text(self.viewModel.toTitle)
                                .font(.rbtLargeTitle)
                                .padding(Spacing.medium)
                                .decorativeAccessibility()
                        AsyncImage(url: URL(string: viewModel.model.mediaUrl))
                            .aspectRatio(contentMode: .fit)
                            .accessibilityLabel(viewModel.model.mediaUrl.isEmpty ? "No image" : "Image for \(self.viewModel.toTitle)")
                    }.overlay(
                        HStack(alignment: .top){
                            Spacer()
                            Button(action:{
                                edit = true
                            }, label: {
                                Label("Edit", systemImage: "pencil.circle.fill")
                                    .labelStyle(.iconOnly)
                            })
                            .accessibleTouchTarget(label: "Edit \(self.viewModel.toTitle)", hint: "Tap to edit this item")
                            .padding(Spacing.small)
                        }
                    , alignment: .top)
                    .overlay(
                        HStack{
                            VStack{
                                Text(viewModel.model.note)
                                    .font(.rbtBody)
                                    .foregroundColor(DesignTokens.primaryText)
                                    .padding(Spacing.small)
                                    .accessibilityLabel("Note: \(viewModel.model.note.isEmpty ? "No note added" : viewModel.model.note)")
                            }
                        }.frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            alignment: .topLeading
                        ).background(DesignTokens.secondaryBackground.opacity(0.8))
                    , alignment: .bottom)
                }
        }
    }
}


struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemView(model: Item(id: UUID(), mediaUrl: "https://www.google.com", type: .Rose, note: "some text"))
    }
}
