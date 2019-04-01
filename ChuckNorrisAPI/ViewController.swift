//
//  ViewController.swift
//  ChuckNorrisAPI
//
//  Created by Andre Paganin on 26/03/19.
//  Copyright © 2019 Andre Paganin. All rights reserved.
//

import UIKit
import SQLite3


//MARK:-Variaveis
let caminhoParaSandbox = NSHomeDirectory()
let pathDocuments = (caminhoParaSandbox as NSString).appendingPathComponent("Documents")
let pathArquivo = (pathDocuments as NSString).appendingPathComponent("arquivo.sqlite")


class ViewController: UIViewController {
    
    //MARK:- Outlets
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    
    var categorias: [String] = []
    var dataBase: OpaquePointer? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        
        //Para verificar se o banco existe
        if (FileManager.default.fileExists(atPath: pathArquivo)) {
            
            self.carregarCategoriasDoBanco()
            
        } else {
            
            self.criarBancoETabela()
        }
    }
    
    func criarBancoETabela(){
        
        
        //Caso o banco não existir ai cria o banco.
        if(sqlite3_open(pathArquivo, &dataBase) == SQLITE_OK) {
            
            //Banco criado.
            print("Banco criado com sucesso")
            
            //Montando  a tabela
            let comando = "create table if not exists CATEGORIAS (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, categoria TEXT)"
            
            //Função que executa um comando sqlite sem retorno do banco
            
            if(sqlite3_exec(dataBase, comando, nil, nil, nil) == SQLITE_OK) {
                
                print("Tabela criada com sucesso")
                
                self.buscaServidor()
                
            }else {
                
                print("Erro na criação da tabela")
            }
            
        }else {
            
            print("Erro na criação do banco")
        }
    }
    
    func carregarCategoriasDoBanco() {

        //Abre o banco
        if(sqlite3_open(pathArquivo, &dataBase) == SQLITE_OK) {
            
            //Quando o banco é aberto
            print("Banco aberto com sucesso")
            
            
            //Criando o comando para resgatar/buscar os dados da tabela
            let comando = "select * from CATEGORIAS"
            
            //Variavel que armazenará o valor resgatado pelo select
            var resultado: OpaquePointer? = nil
            
            //Função que executa um comando com retorno no banco
            if(sqlite3_prepare_v2(dataBase, comando, -1, &resultado, nil) == SQLITE_OK) {
                
                //Laço para percorrer todos os registros
                while(sqlite3_step(resultado) == SQLITE_ROW){
                    
                    //Resgatando as informações
                    var categoria = ""
                    
                    if let cCategoria = sqlite3_column_text(resultado, 1) {
                        
                        categoria = String(cString: cCategoria)
                    }
                    
                    self.categorias.append(categoria)
                }
                
                sqlite3_finalize(resultado)
                
                self.pickerView.reloadAllComponents()
                
            }else {
                
                print("Erro no resgate")
            }
            
        }else {
            
            //Caso haja problemas ao abrir o banco
            print("Erro ao abrir o banco")
        }
        
    }
    
    // Função para pegar a API
    func buscaServidor(){
        
        if let url = URL(string: "https://api.chucknorris.io/jokes/categories") {
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                
                
                if let error = error {
                    
                    print(error.localizedDescription)
                    return
                }
                
                if let data = data,
                    let categorias = try? JSONDecoder().decode([String].self, from: data) {
                    
                    self.categorias = categorias
                    
                    self.gravarCategoriasBanco(categorias: categorias)
                    
                    DispatchQueue.main.async {
                        
                        self.pickerView.reloadAllComponents()
                    }
                }
                
                }.resume()
            
        }
        
    }
    
    func gravarCategoriasBanco(categorias: [String]){
        
        for categoria in categorias {
            // Criando comando para salvar
            let comando = "insert into CATEGORIAS values(NULL, '\(categoria)')"
            
            if(sqlite3_exec(self.dataBase, comando, nil, nil, nil) == SQLITE_OK) {
                
                //Registro criado com sucesso
                print("Registro criado com sucesso")
                
            }else {
                
                //Falha ao criar o registro
                print("Falha ao criar o registro")
                
            }
        }
        
    }
    
    @IBAction func pegarPiada(_ sender: UIButton) {
        
        
        let indexSelecionado = self.pickerView.selectedRow(inComponent: 0)
        let categoriaSelecionada = self.categorias[indexSelecionado]
        
        if let url = URL(string: "https://api.chucknorris.io/jokes/random?category=\(categoriaSelecionada)") {
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                
                if let error = error {
                    
                    print(error.localizedDescription)
                    return
                }
                
                if let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let dicionario = json as? [String : AnyObject],
                    let piada = dicionario["value"] as? String {
                    
                    let alerta = UIAlertController(title: "Piada...", message: piada, preferredStyle: .alert)
                    
                    let acaoCancelar = UIAlertAction(title: "Fechar", style: .cancel, handler: { (action) in
                        
                    })
                    
                    alerta.addAction(acaoCancelar)
                    
                    self.present(alerta, animated: true, completion: nil)
                    
                    
                }
                }.resume()
        }
    }
}

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        //O count faz com o numero de categoarias seja sempre o numero recebido de itens e nao um numero especifico.
        return self.categorias.count
    }
    
    
}
extension ViewController: UIPickerViewDelegate {
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return self.categorias[row]
    }
}
