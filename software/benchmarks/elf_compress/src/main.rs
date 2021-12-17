use clap::{Arg, App};
use std::fs;
use elf_compress;

fn main(){
    let matches = App::new("clam")
        .version("1.0")
        .author("M gould <mdg2838@rit.edu>")
        .about("compresses generated binary into elf.")
        .arg(Arg::new("SRC_PATH")
        	.long("src_path")
        	.required(false)
        	.takes_value(true)
        	.default_value("program"))
        .arg(Arg::new("DEST_PATH")
        	.long("dest_path")
        	.required(false)
        	.takes_value(true)
        	.default_value("program"))
        .arg(Arg::new("INFO_STR")
        	.long("info_str")
        	.required(false)
        	.takes_value(true)
        	.default_value("_info.txt"))
        .arg(Arg::new("DATA_STR")
        	.long("data_str")
        	.required(false)
        	.takes_value(true)
        	.default_value("_compressed.txt"))
        .arg(Arg::new("SECTION_STR")
        	.long("section_str")
        	.required(false)
        	.takes_value(true)
        	.default_value("_sections.txt")).get_matches();

let info_str=format!("{}{}",matches.value_of("SRC_PATH").unwrap(),matches.value_of("INFO_STR").unwrap());
let section_str=format!("{}{}",matches.value_of("DEST_PATH").unwrap(),matches.value_of("SECTION_STR").unwrap());
let data_output_str=format!("{}{}",matches.value_of("DEST_PATH").unwrap(),matches.value_of("DATA_STR").unwrap());
let data_input_str=format!("{}{}",matches.value_of("SRC_PATH").unwrap(),".txt");

	//check file existence
    if !fs::metadata(&info_str).is_ok(){
        panic!("Error! Input file {} does not exist",&info_str);
    }
    let section_info=elf_compress::compress::get_sections(&info_str,&section_str);
    elf_compress::compress::get_data(&section_info,&data_input_str,&data_output_str);
}


