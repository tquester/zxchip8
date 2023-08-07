package de.quester.c8disass;

import java.io.File;


import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.Stack;
import java.util.TreeMap;
import java.util.TreeSet;





public class CC8Decoder {

	int labelNr = 0;
	long bytesRead;
	class CC8Label {
		public enum LabelType {
			NONE,
			CODE,				// code label, jump, call
			DATA,				// data label, i := ___
			SKIP				// target for a skip operation, usually invisible
		};

		public enum DataLabelType {
			NONE,				// generic data db $xx
			SPRITE8,			// 8 bit wide sprite with graphical comment: db $xx 	; ####....
			SPRITE16,			// 8 bit wide sprite with graphical comment: db $xx 	; ####....####....
			ASCII,				// Ascii characters
			LETTERS,			// Letters but in any other format (requires alphabet to be set)
		};

		public LabelType 		mLabelType = LabelType.NONE;
		public DataLabelType 	mDataLabelType = DataLabelType.NONE;
		public int 				mNr;
		public String			mName = null;
		public String			mAlphabet = null;
		public int				mTarget=0;
		
		CC8Label() {
			mNr = labelNr++;
		}
		
		CC8Label(LabelType type) {
			mNr = labelNr++;
			mLabelType = type;
		}
		
		public String toString() {
			if (mName != null) return mName;
			switch(mLabelType) {
				case CODE:	return String.format("label%d", mNr);
				case DATA:	return String.format("data%d", mNr);
				case SKIP:	return String.format("skip%d", mNr);
				default:
					return String.format("undef%d", mNr);
			}
		}
	}

	byte chip8Memory[] = new byte[4096];
	TreeMap<Integer, CC8Label> mLabels = new TreeMap<>();
	TreeSet<Integer> mSetVisited = new TreeSet();
	Stack<Integer> mStackCodeBlocks = new Stack<>();
	private C8DisassEmitter emitter;

	public void start(String filename, String outfile, boolean disassFormat, boolean hex) {
		int size = loadGame(filename);
		int pc = 0x200;
		
		emitter = new C8DisassEmitter();
		emitter.mLabels = mLabels;
		emitter.disassFormat = disassFormat;
		emitter.hexadecimal = hex;

		crawl(pc);
		while (!mStackCodeBlocks.isEmpty()) {
			Integer adr = mStackCodeBlocks.pop();
			if (adr == null) break;
			if (mSetVisited.contains(adr)) continue;
			crawl(adr);
		}
		System.out.println("============ complete dump ==================");
		dumpAll(0x200);
		saveText(outfile, emitter.mSB.toString());
	}

	private void saveText(String outfile, String string) {
		try {
			PrintWriter pw = new PrintWriter(outfile);
			pw.println(string);
			pw.close();
		} catch(Exception e)
		{
			e.printStackTrace();
		}
		
	}

	void addCodeLabel(int adr) {
		CC8Label lbl;
		lbl = mLabels.get(adr);
		if (lbl != null) return;
			
		lbl	= new CC8Label(CC8Label.LabelType.CODE);
		mLabels.put(adr, lbl);

	}
	
	void addDataLabel(int adr) {
		CC8Label lbl;
		lbl = mLabels.get(adr);
		if (lbl != null) return;
		//System.out.println(String.format("Add data Label %4x %d",adr,adr));
			
		lbl	= new CC8Label(CC8Label.LabelType.DATA);
		mLabels.put(adr, lbl);

	}
	
	private CC8Label saveSkipLabel(CC8Label skipLabel, int pc) {
		if (skipLabel != null) {
			skipLabel.mTarget = pc;
			mLabels.put(pc, skipLabel);
		}
		return null;
	}
	
	/* crawl walks through a block of code until we find an unconditional jp or a ret
	 * if we find any i := const a data label is produced
	 * if we find any jp or call, a code label is produced and the target is put onto the stack
	 * for each skip, we produce a skip label. this is not really helpful in chip8 disassembly but we need it for 
	 * other emitters, for example the z80 assembly emitter.
	 *  
	 */

	void crawl(int pc) {
		//System.out.println(String.format("---- crawling %x ------",pc));
		addCodeLabel(pc);
		boolean inSkip = false;
		boolean stop = false;
		CC8Label skipLabel = null;
		while (stop == false) {
		/*	if (pc == 0x029e) {
				System.out.println("debug");
			} 
			emitter.emitOpcode(chip8Memory, pc);
			*/
			mSetVisited.add(pc);
			int high = chip8Memory[pc] & 0xff;
			int low  = chip8Memory[pc+1] & 0xff;
			byte highnib = (byte) (high >>> 4);
			byte lownib1 = (byte)(low >> 4);
			byte lownib2 = (byte) (low & 0x0f);
			byte high2 	 = (byte) (high & 0xf);
			
			
			switch(highnib) {
			case 0x00:
					if (low == 0xee) { // return
						if (!inSkip) stop = true;
					}
					break;
			case 0x01:
			case 0x0b:
			case 0x02: {
					int adr = high2 * 256 + low;
					//System.out.println(String.format("Pushing adr %x",adr));
					mStackCodeBlocks.push(adr);
					addCodeLabel(adr);
				}
				if ((highnib == 0x01 || highnib == 0x0b) && !inSkip) stop=true;
				skipLabel = saveSkipLabel(skipLabel, pc);
				inSkip = false;
				break;
			case 0x03:
			case 0x04:
			case 0x05:
			case 0x09:
				saveSkipLabel(skipLabel, pc);
				skipLabel = new CC8Label(CC8Label.LabelType.SKIP);
				inSkip = true;
				break;
			case 0x0a:  {
				int adr = high2 * 256 + low;
				addDataLabel(adr);
				skipLabel = saveSkipLabel(skipLabel, pc);
				inSkip = false;
			}
				break;
			case 0x0e:
				switch(low) {
				case 0x9e: 
				case 0xa1:
					inSkip = true;
					saveSkipLabel(skipLabel, pc);
					skipLabel = new CC8Label(CC8Label.LabelType.SKIP);
					break;
				default:
					skipLabel = saveSkipLabel(skipLabel, pc);
					inSkip = false;
				}
				break;
				
			default:
				skipLabel = saveSkipLabel(skipLabel, pc);
				inSkip = false;
			}
		
			pc+=2;
		}
		
	}
	


	void dumpAll(int pc) {
		emitter.clear();
		while (pc < 0x200+bytesRead ) {
			if (mSetVisited.contains(pc)) {
				emitter.emitOpcode(chip8Memory, pc);
				pc+=2;
			} else {
				emitter.emitdb(chip8Memory, pc);
				pc++;
			}
			
			
		}
	}

	int loadGame(String filename) {
		bytesRead = 0;
		try (InputStream inputStream = new FileInputStream(filename);) {
			long fileSize = new File(filename).length();
			byte gameBytes[] = new byte[(int) fileSize];
			bytesRead = inputStream.read(gameBytes);
			inputStream.close();
			int source = 0;
			int target = 0x200;
			for (int i = 0; i < bytesRead; i++) {
				chip8Memory[target + i] = gameBytes[source + i];
			}
			return (int) bytesRead;

		} catch (IOException ex) {
			ex.printStackTrace();
			return 0;
		}
	}

}
