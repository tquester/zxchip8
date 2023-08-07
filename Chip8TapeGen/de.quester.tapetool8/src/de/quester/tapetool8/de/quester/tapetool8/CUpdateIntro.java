package de.quester.tapetool8;

import java.io.*;

public class CUpdateIntro {
	
	byte[] tapeBytes = null;
	byte[] gameBytes = null;
	int bytesRead=0;
	
	public void updateIntro( String inputTapeFilename, 
							String chip8Filename, 
							String outputTapeFilename)
	{
		if (loadTape(inputTapeFilename)) {
			boolean found=false;
			String such = "$chip8memory$";
			char first = such.charAt(0);
			for (int i=0;i<bytesRead;i++) {
				char c = (char)tapeBytes[i];
				if (c == first) {
					found=true;
					for (int j=1;j<such.length();j++) {
						if (such.charAt(j) != (char)tapeBytes[i+j]) {
							found = false;
							break;
						}
					}
					if (found) {
						int pos = i + such.length();
						int gamelen = loadGame(chip8Filename);
						if (gamelen == 0) {
							System.out.println("Game "+chip8Filename+" not found");
							return;
						}
						int start = i + 0x200+such.length();
						for (int j=0;j<gamelen;j++) {
							tapeBytes[start+j] = gameBytes[j];
						}
						CTap tap = new CTap();
						tap.readBytes(tapeBytes, tapeBytes.length, true);
						saveTape(outputTapeFilename);
						System.out.println(outputTapeFilename+" written");
						break;
					}
				}
				
			}
			if (!found) 
				System.out.println("entrypoint in tape not found");
			
		} else {
			System.out.println("Error loading tape");
		}
		
	}
	
	private void saveTape(String filename) {
		try {
			OutputStream outputStream = new FileOutputStream(filename);
			outputStream.write(tapeBytes);
			outputStream.close();
		} catch(Exception e) {
			e.printStackTrace();
		}
		
	}

	private OutputStream FileOutputStream(String filename) {
		// TODO Auto-generated method stub
		return null;
	}

	int loadGame(String filename) {
		long bytesRead = 0;
		try (InputStream inputStream = new FileInputStream(filename);) {
			long fileSize = new File(filename).length();
			gameBytes = new byte[(int) fileSize];
			bytesRead = inputStream.read(gameBytes);
			inputStream.close();
			return (int)bytesRead;
	
		} catch (IOException ex) {
			ex.printStackTrace();
			return 0;
		}
	}
	
	boolean loadTape(String filename) {
		try (InputStream inputStream = new FileInputStream(filename);) {
			long fileSize = new File(filename).length();
			tapeBytes = new byte[(int) fileSize];
			bytesRead = inputStream.read(tapeBytes);
			inputStream.close();
			return true;
	
		} catch (IOException ex) {
			ex.printStackTrace();
			return false;
		}
	}

}
