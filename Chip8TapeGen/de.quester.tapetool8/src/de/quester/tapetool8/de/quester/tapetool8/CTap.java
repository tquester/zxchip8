package de.quester.tapetool8;

import java.io.*;
import java.util.ArrayList;

public class CTap {
	enum ZXType {
		Program,
		ByteArray,
		IntArray,
		Code
	}
	ArrayList<ZXTapeEntry> entries = new ArrayList<>();
	public class ZXTapeEntry {
		byte type;
		String name;
		int start;
		int len;
		byte[] bytes;
		public int startLine;
		public int lenProgram;
		public byte var_name;
		public int startAddress;
		public byte flagByte;
		public int reserved;
		public String typName() {
			switch(type) {
				case 0: return "Program";
				case 1: return "Int Array";
				case 2: return "Char Array";
				case 3: return "Code";
			}
			return "unknown";
		}
		public int par1() {
			switch(type) {
			case 0: return startLine;
			case 1: return 0;
			case 2: return 0;
			case 3: return startAddress;
			}
			return 0;
		}
			
		public int par2() {
			return 0;
		}
			
		
	}
	
	public void loadTape(String filename) {
		try (InputStream inputStream = new FileInputStream(filename);) {
			long fileSize = new File(filename).length();
			byte[] allBytes = new byte[(int) fileSize];
			int bytesRead = inputStream.read(allBytes);
			readBytes(allBytes, bytesRead);

		} catch (IOException ex) {
			ex.printStackTrace();
		}
	}
	
	private int readInt(byte[] bytes, int start) {
		int a = bytes[start] & 0xff;
		int b = bytes[start+1] & 0xff;
		return a+b*256;
	}
	/*
	 *          |------ Spectrum-generated data -------|       |---------|

      13 00 00 03 52 4f 4d 7x20 02 00 00 00 00 80 f1 04 00 ff f3 af a3

      ^^^^^...... first block is 19 bytes (17 bytes+flag+checksum)
            ^^... flag byte (A reg, 00 for headers, ff for data blocks)
               ^^ first byte of header, indicating a code block

      file name ..^^^^^^^^^^^^^
      header info ..............^^^^^^^^^^^^^^^^^
      checksum of header .........................^^
      length of second block ........................^^^^^
      flag byte ...........................................^^
      first two bytes of rom .................................^^^^^
      checksum (checkbittoggle would be a better name!).............^^
	 */
	
	private void readBytes(byte[] allBytes, int bytesRead) {
		readBytes(allBytes, bytesRead, false);
	}
	public void readBytes(byte[] allBytes, int bytesRead, boolean fixChecksum) {
		byte a,b;
		byte idByte;
		byte flags;
		int blocksize;
		int i=0;
		byte checksum=0;
		byte headerType;
		ZXTapeEntry tapeEntry;
		while (i < bytesRead) {
			blocksize = allBytes[i] + allBytes[i+1]*256;   // 19 bytes
			flags = allBytes[i+2];						   // always 0
			checksum = flags;
			i+=3;
			if (flags == 0) {
				int checksumstart = i;
				tapeEntry = new ZXTapeEntry();
				entries.add(tapeEntry);
				tapeEntry.type = allBytes[i];
				i++;
				StringBuilder sb = new StringBuilder();
				for (int j=0;j<10;j++) {
					char c = (char)allBytes[j+i];
					checksum ^= c;
					if (c != 0) {
						sb.append(c);
					}
				}
				
				i+=10;

				tapeEntry.name = sb.toString();
				tapeEntry.len = allBytes[i]+allBytes[i+1]*256;
				 
				i+=2;
				int end = i + tapeEntry.len;
				switch(tapeEntry.type) {
					case 0:	// program
						tapeEntry.startLine = readInt(allBytes,i);
						tapeEntry.lenProgram= readInt(allBytes,i+2);
						break;
					case 1: // num_array
					case 2:	// char_array
						tapeEntry.var_name = allBytes[i+1];
						break;
					case 3: // code
						tapeEntry.startAddress = readInt(allBytes,i+2);
						tapeEntry.reserved = readInt(allBytes,i);
				}
				i+=4;
				byte newChecksum = calcChecksum(allBytes, checksumstart, i-1);
				byte check = allBytes[i];
				if (fixChecksum)
					allBytes[i] = newChecksum;
				i++;
				// newChecksum should be identical to check
				int lenSecond = readInt(allBytes,i);
				
				i+=2;
				tapeEntry.flagByte = allBytes[i++];
				checksumstart = i-1;
				int id=0;
				end = i+lenSecond-2;
				tapeEntry.bytes = new byte[lenSecond-1];
				while (i<end) {
					tapeEntry.bytes[id++] = allBytes[i++];
				}
				check = allBytes[i];
				newChecksum = calcChecksum(allBytes, checksumstart, i-1);
				if (fixChecksum)
					allBytes[i] = newChecksum;
				System.out.println("loaded "+tapeEntry.name);
				i++;
			}
		}
	}
	
	byte calcChecksum(byte bytes[], int start, int end) {
		int i;
		byte sum=0;
		for (i=start;i<=end;i++) {
			sum ^= bytes[i];
		}
		return sum;
				
	}



}
