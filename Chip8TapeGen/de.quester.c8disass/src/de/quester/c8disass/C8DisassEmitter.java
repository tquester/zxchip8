package de.quester.c8disass;

import java.util.TreeMap;

import de.quester.c8disass.CC8Decoder.CC8Label;



public class C8DisassEmitter extends C8Emitter {

	public StringBuilder mSB = new StringBuilder();
	public String line;
	boolean disassFormat = true;
	boolean hexadecimal = false;

	@Override
	public int emitOpcode(byte[] code, int pos) {

		String cmd = "";
		int startpos = pos;
		int high = code[pos] & 0xff;
		int low = code[pos + 1] & 0xff;
		pos += 2;
		byte highnib = (byte) (high >>> 4);
		byte lownib1 = (byte) (low >> 4);
		byte lownib2 = (byte) (low & 0x0f);
		byte high2 = (byte) (high & 0xf);

		switch (highnib) {
		case 0x00:
			switch (low) {
			case 0xE0:
				cmd = "cls";
				break;
			case 0xEE:
				cmd = "ret";
				break;
			case 0xff:
				cmd = "hires";
				break;
			default:
				cmd = String.format("unknown %02x%02x", high, low);

			}
			break;
		case 0x01: {
			int adr = high2 * 256 + low;
			cmd = String.format("jp     %s", lbladr(adr));
			break;
		}
		case 0x02: {
			int adr = high2 * 256 + low;
			cmd = String.format("call   %s", lbladr(adr));
			break;
		}
		case 0x03:
			cmd = String.format("skip   %s != %s", reg(high2), number(low));
			break;
		case 0x04:
			cmd = String.format("skip   %s == %s", reg(high2), number(low));
			break;
		case 0x05:
			cmd = String.format("skip   %s == %s", reg(high2), reg(lownib1));
			break;
		case 0x06:
			cmd = String.format("%s := %s", reg(high2), number(low));
			break;
		case 0x07:
			cmd = String.format("%s += %s", reg(high2), number(low));
			break;
		case 0x08:
			switch (lownib2) {
			case 0x00:
				cmd = String.format("%s := %s", reg(high2), reg(lownib1));
				break;
			case 0x01:
				cmd = String.format("%s |= %s", reg(high2), reg(lownib1));
				break;
			case 0x02:
				cmd = String.format("%s &= %s", reg(high2), reg(lownib1));
				break;
			case 0x03:
				cmd = String.format("%s ^= %s", reg(high2), reg(lownib1));
				break;
			case 0x04:
				cmd = String.format("%s += %s", reg(high2), reg(lownib1));
				break;
			case 0x05:
				cmd = String.format("%s -= %s", reg(high2), reg(lownib1));
				break;
			case 0x06:
				cmd = String.format("%s >>= %s", reg(high2), reg(lownib1));
				break;
			case 0x07:
				cmd = String.format("%s =-%s", reg(high2), reg(lownib1));
				break;
			case 0x0E:
				cmd = String.format("%s <<= %s", reg(high2), reg(lownib1));
				break;
			}
			break;
		case 0x09:
			cmd = String.format("skip   %s == %s", reg(high2), reg(lownib1));
			break;
		case 0x0A: {
			int adr = high2 * 256 + low;
			cmd = String.format("i := %s", lbladr(adr));
			break;
		}

		case 0x0B: {
			int adr = high2 * 256 + low;
			cmd = String.format("jump     i,%s+v0", lbladr(adr));
			break;
		}
		case 0x0C:
			cmd = String.format("%s := rnd %s", reg(high2), number(low));
			break;
		case 0x0D:
			cmd = String.format("sprite %s %s %d", reg(high2), reg(lownib1), lownib2);
			break;
		case 0x0E:
			switch (low) {
			case (byte) 0x9e:
				cmd = String.format("skip   key %s", reg(high2));
				break;

			case (byte) 0xa1:
				cmd = String.format("skip   -key %s", reg(high2));
				break;
			}
			break;
		case 0x0F:
			switch (low) {
			case 0x07:
				cmd = String.format("%s := delay", reg(high2));
				break;
			case 0x0a:
				cmd = String.format("%s := key", reg(high2));
				break;
			case 0x15:
				cmd = String.format("delay := %s", reg(high2));
				break;
			case 0x18:
				cmd = String.format("buzz := %s", reg(high2));
				break;
			case 0x1e:
				cmd = String.format("i += %s", reg(high2));
				break;
			case 0x29:
				cmd = String.format("i := char %s", reg(high2));
				break;
			case 0x33:
				cmd = String.format("bcd    %s", reg(high2));
				break;

			case 0x55:
				cmd = String.format("save   %s", reg(high2));
				break;
			case 0x65:
				cmd = String.format("load   %s", reg(high2));
				break;
			}
			break;

		}
		CC8Label lbl = mLabels.get(startpos);
		String strlbl = "";
		if (lbl != null) {
			strlbl = lbl.toString() + ":";
		}
		if (disassFormat)
			line = String.format("%04x %-10s %02x %02x       %s", startpos, strlbl, high, low, cmd);
		else
			line = String.format("%-10s        %s", strlbl, cmd);
			
		System.out.println(line);
		mSB.append(line + "\n");

		return pos;
	}

	String reg(int reg) {
		if (reg < 10)
			return String.format("v%d", reg);
		else
			return String.format("v%c", reg + 55);
	}
	
	String lbladr(int adr) {
		CC8Label lbl = mLabels.get(adr);
		if (lbl == null)
			return String.format("%x", adr);
		else
			return String.format("%s\t;%x", lbl.toString(),adr);
	}

	@Override
	protected void clear() {
		mSB = new StringBuilder();
		
	}
	
	String number(int nr) {
		if (hexadecimal) return String.format("%02x", nr);
		int nr2 = nr;
		if (nr > 127) nr = -(256-nr);
		return String.format("%d\t;%02x", nr, nr2);
	}

	@Override
	protected void emitdb(byte[] chip8Memory, int pc) {
		int data = chip8Memory[pc] & 0xff;
		CC8Label lbl = mLabels.get(pc);
		String strlbl = "";
		if (lbl != null) {
			strlbl = lbl.toString();
		}

		String comment=Integer.toBinaryString(data).replaceAll("0", " ").replaceAll("1", "#");
		while (comment.length() < 8) comment = "_"+comment;
		
		if (data > 32 && data <= 127) comment += String.format("  %c", data);
		line = String.format("%04x %10s             db %02x\t;%s", pc, strlbl, data,comment);
		System.out.println(line);
		mSB.append(line + "\n");
		
	}

}
