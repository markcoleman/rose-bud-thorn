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
        VStack{
            HStack{
                Text("Add New RBT")
                Text(viewModel.dateString())
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ItemView(model: self.viewModel.model!.rose)
                .frame(minWidth:0, maxWidth: .infinity)
            ItemView(model: self.viewModel.model!.bud)
                .frame(minWidth:0, maxWidth: .infinity)
            ItemView(model: self.viewModel.model!.thorn).frame(minWidth:0, maxWidth: .infinity)
            
            Button("Save"){
                viewModel.save()
            }
        } .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        ).onAppear{
            self.viewModel.load()
        }
    }
}

struct AddNewRBTView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewRBTView(viewModel: DayViewModel(date: Date()))
    }
}
