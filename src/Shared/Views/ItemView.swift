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
                    VStack{
                        Section(header: Text(self.viewModel.toTitle)
                                    .font(.system(size: 50)) )
                        {                            TextField(
                                    "Note",
                                    text: $viewModel.model.note
                            ).padding()
                            TextField(
                                    "media url",
                                    text: $viewModel.model.mediaUrl
                            ).padding()
                        }.textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack{
                            Button(action:{
                                edit = false
                            }, label: {
                                Label("Cancel",
                                      systemImage: "xmark.circle.fill")
                            })
                            Button(action:{
                                edit = false
                                viewModel.save()
                            }, label: {
                                Label("Save",
                                      systemImage: "checkmark.circle.fill")
                            })
                        }.padding()
                    }
                }
                else{
                    ZStack(){
                        Text(self.viewModel.toTitle)
                                .font(.system(size: 50)).padding()
                        AsyncImage(url: URL(string: viewModel.model.mediaUrl)).aspectRatio(contentMode: .fit)
                    }.overlay(
                        HStack(alignment: .top){
                            Spacer()
                            Button(action:{
                                edit = true
                            }, label: {
                                Label("Edit",
                                      systemImage: "pencil.circle.fill")
                            }).padding()
                        }
                    , alignment: .top)
                    .overlay(
                        HStack{
                            
                            VStack{
                                Text(viewModel.model.note).padding()
                            }
                        }.frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            alignment: .topLeading
                        ).background(Color.white.opacity(0.5))
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
