using MySql.Data.MySqlClient;
using treasureroller.Models;
using System.Diagnostics;

namespace treasureroller.Services;
public static class TreasureService {
        static TreasureService(){
        }
        private static MySqlConnection GetConnection(){
            return new MySqlConnection("server=localhost;port=3306;database=treasuretables;user=dotnetuser;password=password");
        }

       
        public static List<Treasure> GetAllItems() {
            List<Treasure> list = new List<Treasure>();
            using(MySqlConnection conn = GetConnection()){
                conn.Open();
                MySqlCommand cmd = new MySqlCommand("CALL listallitems()", conn);
                using (MySqlDataReader reader = cmd.ExecuteReader()){
                    while(reader.Read()){
                        int id = (reader["id"] as int?).GetValueOrDefault();
                        string name = (reader["name"] as string) ?? "";
                        string description = (reader["description"] as string) ?? "";
                        int value = (reader["value"] as int?).GetValueOrDefault();
                        bool iscontainer = (reader["iscontainer"] as bool?).GetValueOrDefault();
                        bool isvirtual = (reader["virtual"] as bool?).GetValueOrDefault();
                        Debug.WriteLine($"Id: {id}");
                        Debug.WriteLine($"Name: {name}");
                        Debug.WriteLine($"Description: {description}");
                        Debug.WriteLine($"Value: {value}");
                        Debug.WriteLine($"IsContainer: {iscontainer}");
                        Debug.WriteLine($"IsVirtual: {isvirtual}");
                        list.Add(new Treasure(){
                            Id = id,
                            Name = name,
                            Description = description,
                            Value = value,
                            IsContainer = iscontainer,
                            IsVirtual = isvirtual
                        });
                    }
                }
            }
            return list;
        }
        
        public static List<Treasure> GetContainers() {
            List<Treasure> list = new List<Treasure>();
            using(MySqlConnection conn = GetConnection()){
                conn.Open();
                MySqlCommand cmd = new MySqlCommand("CALL listcontainers()", conn);
                using (MySqlDataReader reader = cmd.ExecuteReader()){
                    while(reader.Read()){
                        int id = (reader["id"] as int?).GetValueOrDefault();
                        string name = (reader["name"] as string) ?? "";
                        string description = (reader["description"] as string) ?? "";
                        int value = (reader["value"] as int?).GetValueOrDefault();
                        bool iscontainer = (reader["iscontainer"] as bool?).GetValueOrDefault();
                        bool isvirtual = (reader["virtual"] as bool?).GetValueOrDefault();
                        Debug.WriteLine($"Id: {id}");
                        Debug.WriteLine($"Name: {name}");
                        Debug.WriteLine($"Description: {description}");
                        Debug.WriteLine($"Value: {value}");
                        Debug.WriteLine($"IsContainer: {iscontainer}");
                        Debug.WriteLine($"IsVirtual: {isvirtual}");
                        list.Add(new Treasure(){
                            Id = id,
                            Name = name,
                            Description = description,
                            Value = value,
                            IsContainer = iscontainer,
                            IsVirtual = isvirtual
                        });
                    }
                }
            }
            return list;
        }

        // public static List<Dictionary> GetLanguages

        public static List<Treasure> GetTreasures(int topid, int topqty, int lang) {
            List<Treasure> list = new List<Treasure>();
            using(MySqlConnection conn = GetConnection()){
                conn.Open();
                MySqlCommand cmd = new MySqlCommand($"CALL rolltreasure({topqty},{topid},{lang})", conn);
                using (MySqlDataReader reader = cmd.ExecuteReader()){
                    while(reader.Read()){
                        int id = reader.GetInt32("id");
                        int amount = reader.GetInt32("amount");
                        string name = (reader["name"] as string) ?? "";
                        string description = (reader["description"] as string) ?? "";
                        int value = (reader["value"] as int?).GetValueOrDefault();
                        Debug.WriteLine($"Id: {id}");
                        Debug.WriteLine($"Name: {name}");
                        Debug.WriteLine($"Quantity: {amount}");
                        Debug.WriteLine($"Description: {description}");
                        Debug.WriteLine($"Value: {value}");
                        list.Add(new Treasure(){
                            Id = id,
                            Quantity = amount,
                            Name = name,
                            Description = description,
                            Value = value
                        });
                    }
                }
            }
            return list;
        }
    }