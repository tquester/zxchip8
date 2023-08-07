package de.quester.c8disass;

import java.util.TreeMap;

import de.quester.c8disass.CC8Decoder.CC8Label;



public abstract class C8Emitter {
	TreeMap<Integer, CC8Label> mLabels = new TreeMap<>();
	public abstract int emitOpcode(byte[] code, int pos);
	protected abstract void clear();
	protected abstract void emitdb(byte[] chip8Memory, int pc);
	

}
