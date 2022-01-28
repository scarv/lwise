#ifdef __GNUC__
#ifndef __USE_GNU
#define __USE_GNU
#endif
#define _GNU_SOURCE
#include <sched.h>
#include <unistd.h> 
#endif
#include "crypto_aead.h"
#include "api.h"
#include "timing_aead.h"


#define MAX_MESSAGE_LENGTH (1UL << 16UL)
#define MAX_ASSOCIATED_DATA_LENGTH (1UL << 16UL)

#ifdef _MSC_VER
#define DUAL_CORE

#if defined( DUAL_CORE )
#  define WINDOWS_LEAN_AND_MEAN
#  include <windows.h>
#endif
#include <string.h>
#include <math.h>

#include <intrin.h>
#pragma intrinsic( __rdtsc )

__inline unsigned long long read_tsc(void)
{
	return __rdtsc();
}

#if defined( _M_IX86 )
#if _M_IX86 == 500
#define PROCESSOR   "Pentium"
#elif _M_IX86 == 600
#define PROCESSOR   "P2/P3/P4"
#else
#define PROCESSOR   ""
#endif
#elif defined( _M_X64 )
#define PROCESSOR   "AMD64/EMT64"
#else
#define PROCESSOR   ""
#endif

#if defined( _WIN64 )

#define CurrentProcessorNumber GetCurrentProcessorNumber

#else

unsigned long CurrentProcessorNumber(void)
{
    __asm
    {
        mov     eax,1
        cpuid
        shr     ebx,24
        mov     eax, ebx
    }
}

#endif

void setCPUaffinity()
{
#if defined( DUAL_CORE ) && defined( _WIN32 )
    HANDLE ph;
    DWORD_PTR afp;
    DWORD_PTR afs;
    ph = GetCurrentProcess();
    if(GetProcessAffinityMask(ph, &afp, &afs))
    {
        afp &= (1 << CurrentProcessorNumber());
        if(!SetProcessAffinityMask(ph, afp))
        {
            printf("Couldn't set Process Affinity Mask\n\n");
        }
    }
    else
    {
        printf("Couldn't get Process Affinity Mask\n\n");
    }
#endif
}

#else
#ifdef __GNUC__
#include <sched.h>
#include <sys/resource.h>
#include <x86intrin.h>
inline unsigned long long read_tsc(void)
{
#if defined(__i386__)
	unsigned long long cycles;
	__asm__ volatile (".byte 0x0f, 0x31" : "=A"(cycles));
	return cycles;
#else
#if defined(__x86_64__)
	unsigned int hi, lo;
	__asm__ volatile ("rdtsc" : "=a"(lo), "=d"(hi));
	return (((unsigned long long)lo) | ((unsigned long long)(hi)<<32));
#else
#error "Unsupported architecture for counting cycles"
#endif
#endif
}

void setCPUaffinity()
{
	cpu_set_t cpu_mask;
	CPU_SET(0x1, &cpu_mask);
	if(sched_setaffinity(getpid(), sizeof(cpu_mask), &cpu_mask) == -1 )
	{
		printf("Impossible to set CPU affinity...\n");
	}
}
#endif
#endif

#define RAND(a,b) (((a = 36969 * (a & 65535) + (a >> 16)) << 16) + \
	(b = 18000 * (b & 65535) + (b >> 16))  )

void block_rndfill(unsigned char *buf, const size_t len)
{
	static unsigned long a[2], mt = 1, count = 4;
	static unsigned char r[4];
	size_t                  i;

	if(mt) { mt = 0; *(unsigned long long*)a = read_tsc(); }

	for(i = 0; i < len; ++i)
	{
		if(count == 4)
		{
			*(unsigned int*)r = RAND(a[0], a[1]);
			count = 0;
		}

		buf[i] = r[count++];
	}
}

const int loops = 100;  

const int loops_longMessage = 1;

#define SAMPLE1  100
#define SAMPLE2 1000

#define TRUE  1
#define FALSE 0

int timeBase(double *av, double *sig)
{
	volatile int                 i, tol, lcnt, sam_cnt;
	volatile double              cy, av1, sig1;

	tol = 10; lcnt = sam_cnt = 0;
	while(!sam_cnt)
	{
		av1 = sig1 = 0.0;

		for(i = 0; i < SAMPLE1; ++i)
		{
			cy = (volatile double)read_tsc();
			cy = (volatile double)read_tsc() - cy;

			av1 += cy;
			sig1 += cy * cy;
		}

		av1 /= SAMPLE1;
		sig1 = sqrt((sig1 - av1 * av1 * SAMPLE1) / SAMPLE1);
		sig1 = (sig1 < 0.05 * av1 ? 0.05 * av1 : sig1);

		*av = *sig = 0.0;
		for(i = 0; i < SAMPLE2; ++i)
		{
			cy = (volatile double)read_tsc();
			cy = (volatile double)read_tsc() - cy;

			if(cy > av1 - sig1 && cy < av1 + sig1)
			{
				*av += cy;
				*sig += cy * cy;
				sam_cnt++;
			}
		}

		if(10 * sam_cnt > 9 * SAMPLE2)
		{
			*av /= sam_cnt;
			*sig = sqrt((*sig - *av * *av * sam_cnt) / sam_cnt);

			if(*sig > (tol / 100.0) * *av)
				sam_cnt = 0;
		}
		else
		{
			if(lcnt++ == 10)
			{
				lcnt = 0; tol += 5;
				if(tol > 30)
					return FALSE;
			}
			sam_cnt = 0;
		}
	}
	return TRUE;
}

int time_enc16(double *av, double *sig, unsigned long long dataLengthInBytes, unsigned long long AdataLengthInBytes)
{
	volatile int       i, tol, lcnt, sam_cnt;
	volatile double    cy, av1, sig1;
	unsigned char      key[CRYPTO_KEYBYTES];
	unsigned char      nonce[CRYPTO_NPUBBYTES];
	unsigned char      pt[4][MAX_MESSAGE_LENGTH + CRYPTO_ABYTES];
	unsigned char      at[4][MAX_ASSOCIATED_DATA_LENGTH];
	unsigned long long  clen;

	for (i = 0; i < 4; i++)
	{
		block_rndfill(pt[i], dataLengthInBytes);
		block_rndfill(at[i], AdataLengthInBytes);
	}

	block_rndfill(key, CRYPTO_KEYBYTES);
	block_rndfill(nonce, CRYPTO_NPUBBYTES);

	tol = 10; lcnt = sam_cnt = 0;
	while(!sam_cnt)
	{
		av1 = sig1 = 0.0;

		for(i = 0; i < SAMPLE1; ++i)
		{
			cy = (double)read_tsc();
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			cy = (double)read_tsc() - cy;

			av1 += cy;
			sig1 += cy * cy;
		}

		av1 /= SAMPLE1;
		sig1 = sqrt((sig1 - av1 * av1 * SAMPLE1) / SAMPLE1);
		sig1 = (sig1 < 0.05 * av1 ? 0.05 * av1 : sig1);

		*av = *sig = 0.0;
		for(i = 0; i < SAMPLE2; ++i)
		{
			cy = (double)read_tsc();
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[0], &clen, pt[0], dataLengthInBytes, at[0], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[1], &clen, pt[1], dataLengthInBytes, at[1], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[2], &clen, pt[2], dataLengthInBytes, at[2], AdataLengthInBytes, NULL, nonce, key);
			crypto_aead_encrypt(pt[3], &clen, pt[3], dataLengthInBytes, at[3], AdataLengthInBytes, NULL, nonce, key);
			cy = (double)read_tsc() - cy;

			if(cy > av1 - sig1 && cy < av1 + sig1)
			{
				*av += cy;
				*sig += cy * cy;
				sam_cnt++;
			}
		}

		if(10 * sam_cnt > 9 * SAMPLE2)
		{
			*av /= sam_cnt;
			*sig = sqrt((*sig - *av * *av * sam_cnt) / sam_cnt);
			if(*sig > (tol / 100.0) * *av)
				sam_cnt = 0;
		}
		else
		{
			if(lcnt++ == 10)
			{
				lcnt = 0; tol += 5;
				if(tol > 30)
				{
					return FALSE;
				}
			}
			sam_cnt = 0;
		}
	}
	return TRUE;
}

double enc_cycles(unsigned long long dataLengthInBytes, unsigned long long AdataLengthInBytes)
{
	volatile double cy1, cy2, c1 = -1, c2 = -1;
	volatile int i;
	unsigned char      key[CRYPTO_KEYBYTES];
	unsigned char      nonce[CRYPTO_NPUBBYTES];
	unsigned char      pt[MAX_MESSAGE_LENGTH + CRYPTO_ABYTES];
	unsigned char      at[MAX_ASSOCIATED_DATA_LENGTH];
	unsigned long long  clen;

	block_rndfill(key, CRYPTO_KEYBYTES);
	block_rndfill(nonce, CRYPTO_NPUBBYTES);
	block_rndfill(pt, dataLengthInBytes);
	block_rndfill(at, AdataLengthInBytes);

    c1 = c2 = 0xffffffffffffffff;
	crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);

	for(i = 0; i < loops; ++i)
	{
		cy1 = (volatile double)read_tsc();
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		cy1 = (volatile double)read_tsc() - cy1;

		cy2 = (volatile double)read_tsc();
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		crypto_aead_encrypt(pt, &clen, pt, dataLengthInBytes, at, AdataLengthInBytes, NULL, nonce, key);
		cy2 = (volatile double)read_tsc() - cy2;

		if(i > (loops / 10))
		{
			c1 = (c1 < cy1 ? c1 : cy1);
			c2 = (c2 < cy2 ? c2 : cy2);
		}
	}
	return ((c2 - c1) + 4.0) / 8.0;
}

static unsigned long ml[] = { 
	0, 
	1UL << 4UL,
	1UL << 5UL,
	1UL << 6UL,
	1UL << 7UL,
	1UL << 8UL,
	1UL << 9UL,
	1UL << 10UL,
	//1UL << 11UL,
	//1UL << 12UL,
	//1UL << 13UL,
	//1UL << 14UL,
	//1UL << 15UL,
	//1UL << 16UL,
	//1UL << 17UL,
	//1UL << 18UL,
	//1UL << 19UL,
	//1UL << 20UL
	};
static unsigned long al[] = { 
	0, 
	1UL << 4UL,
	1UL << 5UL,
	1UL << 6UL,
	1UL << 7UL,
	1UL << 8UL,
	1UL << 9UL,
	1UL << 10UL,
	//1UL << 11UL,
	//1UL << 12UL,
	//1UL << 13UL,
	//1UL << 14UL,
	//1UL << 15UL,
	//1UL << 16UL,
	//1UL << 17UL,
	//1UL << 18UL,
	//1UL << 19UL,
	//1UL << 20UL
	};


static double et, dt;

#define MAX_FILE_NAME				256

void timing()
{
	FILE *fp;
	char fileName[MAX_FILE_NAME];
	double   a0, av, sig;
	int ki, i, w;
	unsigned long long pi;
	unsigned long long ai;
	unsigned long long di;

	setCPUaffinity();
	sprintf(fileName, "AEAD_Timing_Min_%d_%d.csv", (CRYPTO_KEYBYTES * 8), (CRYPTO_NPUBBYTES * 8));

	if ((fp = fopen(fileName, "a")) == NULL) {
		fprintf(stderr, "Couldn't open <%s> for write\n", fileName);
		return -1;
	}

	fprintf(fp, "Encryption Timing (cycles/byte)\n");
	fprintf(fp, "%20s,", "P_len/AD_len(bytes)");

	for (ai = 0; ai < sizeof(al)/sizeof(unsigned long); ai++)
	{
		fprintf(fp, "%10d,", al[ai]);
	}
	fprintf(fp, "\n");

	for (pi = 0; pi < sizeof(ml)/sizeof(unsigned long); pi++)
	{
		fprintf(fp, "%20d,", ml[pi]);
		for (ai = 0; ai < sizeof(al)/sizeof(unsigned long); ai++)
		{
			et = enc_cycles(ml[pi], al[ai]);
			if ((ml[pi] == 0) && (al[ai] == 0))
			{
				av = et;
			}
			else
			{
				av = et / (ml[pi] + al[ai]);
			}
			fprintf(fp, "%10.2f,", av);
		}
		fprintf(fp, "\n");
	}
	fprintf(fp, "\n");
	fclose(fp);

	sprintf(fileName, "AEAD_Timing_Avg_%d_%d.csv", (CRYPTO_KEYBYTES * 8), (CRYPTO_NPUBBYTES * 8));
	if ((fp = fopen(fileName, "a")) == NULL) {
		fprintf(stderr, "Couldn't open <%s> for write\n", fileName);
		return -1;
	}

	while (timeBase(&a0, &sig) != TRUE) {}
	fprintf(fp, "Encryption Timing (cycles/byte)\n");
	fprintf(fp, "%20s,", "P_len/AD_len(bytes)");
	for (ai = 0; ai < sizeof(al)/sizeof(unsigned long); ai++)
	{
		fprintf(fp, "%20d,", al[ai]);
	}
	fprintf(fp, "\n");
	for (pi = 0; pi < sizeof(ml)/sizeof(unsigned long); pi++)
	{
		fprintf(fp, "%20d,", ml[pi]);
		for (ai = 0; ai < sizeof(al)/sizeof(unsigned long); ai++)
		{
			while (time_enc16(&av, &sig, ml[pi], al[ai]) != TRUE) {}
			sig *= 100.0 / av;
			if ((ml[pi] == 0) && (al[ai] == 0))
			{
				av = (int)(10.0 * (av - a0) / (16.0)) / 10.0;
				sig = (int)(10 * sig) / 10.0;
			}
			else
			{
				av = (int)(10.0 * (av - a0) / (16.0 * (ml[pi] + al[ai]))) / 10.0;
				sig = (int)(10 * sig) / 10.0;
			}
			fprintf(fp, "%10.2f(%7.2f\%),", av, sig);
		}
		fprintf(fp, "\n");
	}
	fprintf(fp, "\n");
	fclose(fp);
}

int main()
{
	timing();
	return 0;
}

