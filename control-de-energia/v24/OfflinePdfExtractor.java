package com.controlenergia.app;

import android.content.Context;
import android.util.Base64;
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.text.PDFTextStripper;
import com.tom_roush.pdfbox.text.TextPosition;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/** Preserva columnas y filas del PDF de EDESUR para recuperar lecturas, kWh y total. */
public final class OfflinePdfExtractor {
    private OfflinePdfExtractor(){}
    private static final int MAX_RUNS=90000;
    static final class Run {
        final float x,y;
        final String text;
        Run(float x,float y,String text){this.x=x;this.y=y;this.text=text;}
    }
    static final class Row {
        final float y;
        final List<Run> runs=new ArrayList<>();
        Row(float y){this.y=y;}
    }
    static final class PositionedStripper extends PDFTextStripper {
        private final List<Run> runs=new ArrayList<>();
        PositionedStripper() throws IOException {
            super();
            setSortByPosition(true);
            setStartPage(1);
            setEndPage(2);
        }
        @Override protected void writeString(String text,List<TextPosition> positions) throws IOException {
            if(text==null||text.trim().isEmpty()||positions.isEmpty())return;
            if(runs.size()>MAX_RUNS)throw new IOException("Texto PDF demasiado extenso");
            TextPosition first=positions.get(0);
            runs.add(new Run(first.getXDirAdj(),first.getYDirAdj(),text.trim()));
        }
        String reconstruct(){
            if(runs.isEmpty())return "";
            List<Run> ordered=new ArrayList<>(runs);
            Collections.sort(ordered,(a,b)->{
                int compare=Float.compare(a.y,b.y);
                return compare!=0?compare:Float.compare(a.x,b.x);
            });
            List<Row> rows=new ArrayList<>();
            for(Run run:ordered){
                Row row=null;
                for(int n=rows.size()-1;n>=0;n--){
                    Row candidate=rows.get(n);
                    if(Math.abs(candidate.y-run.y)<=2.8f){row=candidate;break;}
                    if(candidate.y<run.y-3.3f)break;
                }
                if(row==null){row=new Row(run.y);rows.add(row);}
                row.runs.add(run);
            }
            Collections.sort(rows,Comparator.comparingDouble(r->r.y));
            StringBuilder out=new StringBuilder();
            for(Row row:rows){
                Collections.sort(row.runs,Comparator.comparingDouble(r->r.x));
                StringBuilder line=new StringBuilder();
                for(Run run:row.runs){
                    if(line.length()>0)line.append(' ');
                    line.append(run.text);
                }
                if(line.length()>0){
                    if(out.length()>0)out.append('\n');
                    out.append(line);
                }
            }
            return out.toString();
        }
    }
    public static String extract(Context context,String encoded) throws Exception {
        if(encoded==null||encoded.length()>18000000)throw new IllegalArgumentException("PDF demasiado grande");
        byte[] data=Base64.decode(encoded,Base64.DEFAULT);
        if(data.length<8||data.length>12000000||data[0]!='%'||data[1]!='P'||data[2]!='D'||data[3]!='F')
            throw new IllegalArgumentException("El adjunto no es un PDF válido");
        PDFBoxResourceLoader.init(context.getApplicationContext());
        try(PDDocument document=PDDocument.load(data)){
            if(document.isEncrypted())throw new IllegalArgumentException("PDF con contraseña");
            if(document.getNumberOfPages()<1)throw new IllegalArgumentException("PDF sin páginas");
            PositionedStripper stripper=new PositionedStripper();
            stripper.getText(document);
            String rows=stripper.reconstruct();
            if(rows.length()<100)throw new IllegalArgumentException("No hay texto legible en el PDF");
            return rows;
        }
    }
}
