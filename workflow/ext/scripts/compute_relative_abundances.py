import argparse
from os.path import abspath, basename, join
import pandas as pd
from functools import reduce


def main(args):         
    len_df = pd.read_csv(args.ann,sep='\t',index_col=6).loc[:,['Start','Stop']]
    len_df['gene_length'] = len_df.Stop - len_df.Start
    aligned_lst = []
    for i in args.genes.split(','):
        df = pd.read_csv(i,index_col=0,sep=' ',header=None)
        df.columns=[i.split('/')[-1].replace('.tsv','')]
        aligned_lst.append(df)
    align_df = reduce(lambda x, y: pd.merge(x, y, left_index = True,right_index = True), aligned_lst)
    abund_df = pd.merge(len_df,align_df,left_index=True,right_index=True).drop(['Start','Stop'],axis=1)
    abund_df.to_csv(join(args.out_dir, 'merged_read_cts.tsv'),sep='\t')
    for i in abund_df.columns[1:]:
        temp = abund_df.loc[:,i]/abund_df.gene_length
        temp2 = temp/temp.sum()
        abund_df.loc[:,i] = temp2
    abund_df.to_csv(join(args.out_dir, 'merged_rel_abund.tsv'),sep='\t')



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ann", help="De novo gene annotations in a single sample")
    parser.add_argument("genes", help="DIAMOND gene annotations in a single sample")    
    parser.add_argument("out_dir", help="Output directory")
    args = parser.parse_args()
    main(args)
