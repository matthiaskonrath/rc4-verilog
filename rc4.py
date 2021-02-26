"""
---- ---- ---- ---- ---- ---- ---- ----
            Information
---- ---- ---- ---- ---- ---- ---- ----
Author: Matthias Konrath
Email:  matthias AT inet-sec.at
Title:  RC4 Implementation (python 2.7)
Source: https://en.wikipedia.org/wiki/RC4
Check:  https://gchq.github.io/CyberChef/#recipe=RC4(%7B'option':'Hex','string':'ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405'%7D,'Hex','Hex')&input=M2FlMjgwZDBkNWNkNzBkOGUwZjgxMzAwZGM5MDMxYTJlMGY4NTEyY2IzNWE3NTc5ZmQ3OTU3NWNmMjg3YzU5NQ

---- ---- ---- ---- ---- ---- ---- ----
                LICENSE
---- ---- ---- ---- ---- ---- ---- ----
MIT License

Copyright (c) 2021 Matthias Konrath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
from timeit import default_timer as timer

def KSA(key_hex, key_length):
    """
        Key-scheduling algorithm
    """
    # Initialize the variables
    j = 0
    array_s = []
    
    # Initialize the array
    for i in range(256):
        array_s.append(i)
    
    # Run the algorithm
    for i in range(256):
        j = (j + array_s[i] + ord(key_hex[i % key_length])) % 256
        tmp = array_s[i]
        array_s[i] = array_s[j]
        array_s[j] = tmp
    return array_s



def PRGA(array_s, payload_length):
    """
        Pseudo-random generation algorithm
    """
    # Initialize the variables
    j = 0
    i = 0
    k = 0
    keystream = []

    # Run the algorithm
    for _ in range(payload_length):
        i = (i + 1) % 256
        j = (j + array_s[i]) % 256
        tmp = array_s[i]
        array_s[i] = array_s[j]
        array_s[j] = tmp
        k = array_s[(array_s[i] + array_s[j]) % 256]
        keystream.append(k)

    return keystream



#### #### #### ####
#  MAIN FUNCTION  #
#### #### #### ####
print '---- ---- ---- ---- ---- ---- ---- ----'
print '      RC4 Python Implementation        '
print '---- ---- ---- ---- ---- ---- ---- ----'
print 'Author: Matthias Konrath'
print 'Email:  matthas AT inet-sec.at'
print '\n'

key_str = "ae6c3c41884d35df3ab5adf30f5b2d360938c658341886b0ba510b421e5ab405"
key_hex = key_str.decode("hex")
key_length = len(key_str)/2

payload_str = "3ae280d0d5cd70d8e0f81300dc9031a2e0f8512cb35a7579fd79575cf287c595"
payload_str_hex = payload_str.decode("hex")
payload_str_length = len(payload_str)/2

cyphertext = []

print '[*] KEY:'
print key_str
print ''
print '[*] Payload:'
print payload_str
print ''

array_s = KSA(key_hex, key_length)
print '[*] ARRAY_S:'
print ''.join('{:02x}'.format(x) for x in array_s)
print ''

keystream = PRGA(array_s, payload_str_length)
print '[*] KEYSTREAM:'
print ''.join('{:02x}'.format(x) for x in keystream)
print ''

print '[*] CIPHERTEXT:'
for i in range(payload_str_length):
    cyphertext.append(ord(payload_str_hex[i]) ^ keystream[i])
print ''.join('{:02x}'.format(x) for x in cyphertext)
print ''


print '[*] SPEED TEST'
test_size_bytes = 10000000
payload_str = "a" * test_size_bytes
payload_str_hex = payload_str.decode("hex")
payload_str_length = len(payload_str)/2

start = timer()
array_s = KSA(key_hex, key_length)
keystream = PRGA(array_s, payload_str_length)
stop = timer()
print '[+] Encrypted {} MB in {:.2f} seconds ({:.2f} MB/s)'.format((test_size_bytes / 1000000), (stop - start), (float(test_size_bytes) / float(stop - start)) / 1000000)
