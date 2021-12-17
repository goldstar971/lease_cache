pub mod compress {
	  
		use std::fs::File;
		use std::io::{BufRead, BufReader,Write,Read,ErrorKind};

		pub fn get_sections(
			info_file:&str, 
			section_file:&str)->Vec<(u64,u64)>{
				let mut addrs_sizes:Vec<(u64,u64)>=Vec::new();
				let sect_file=File::open(info_file).unwrap();
			let reader=BufReader::new(sect_file);
			//get section data and store it in map
			for line in reader.lines(){
				if line.as_ref().unwrap().contains("LOAD"){
					let section_line=line.unwrap();
					let mut fields=section_line.split_whitespace();
					addrs_sizes.push((u64::from_str_radix(&fields.nth(3).unwrap()[2..],16).unwrap(),u64::from_str_radix(&fields.next().unwrap()[2..],16).unwrap()));
				}

			}
			//write section data to file
			let mut file=File::create(section_file).expect("create failed");
			for (key,value) in &addrs_sizes{
				file.write_all(&format!("0x{:08x},0x{:x}\n",key,value).as_bytes()).expect("write failed");
			}
				return addrs_sizes;
		}
	pub fn get_data(
		section_info:&Vec<(u64,u64)>, 
		input_data_file:&str,
		output_data_file:&str){
	
		let file=File::open(input_data_file).expect("open failed");
		let mut buffer = [0u8; 4];
		let mut reader =BufReader::new(file);
		let mut numbers:Vec<u32>=Vec::new();
			
		loop {
			 if let Err(e)=reader.read_exact(&mut buffer){
				if e.kind()==ErrorKind::UnexpectedEof{
					break;
				}
			 }
				numbers.push(u32::from_le_bytes(buffer));
		}
		let mut file=File::create(output_data_file).expect("create failed");
		let mut compressed_list:Vec<u32>=Vec::new();
		let mut bound_index=0;
		let mut n_bytes=section_info[bound_index].1;
		let mut bound_low=section_info[bound_index].0;
		let mut bound_high=section_info[bound_index].0+section_info[bound_index].1;
		
		for (index, value) in numbers.iter().enumerate(){
			

		   if 4*index ==bound_high as usize{
		   		
		   		bound_index=bound_index +1;
		   		n_bytes=n_bytes+section_info[bound_index].1;
		   			  bound_low=section_info[bound_index].0;
					bound_high=section_info[bound_index].0+section_info[bound_index].1;
		   }
		   if 4*index>=bound_low as usize && 4*index <bound_high as usize{
		   		compressed_list.push(*value);
		   		file.write_all(format!("{:08x}\n",value).as_bytes()).expect("Write failed!")
		   }
		}
		if compressed_list.len()*4 != n_bytes as usize{
			panic!{"Error: import data error"};
		}
	}
}