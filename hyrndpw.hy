(import hashlib random string sys urllib.request)

(defn get-random-char []
  (random.choice (cut string.printable 0 84)))  

(defn make-charlist [pwlength]
  (list 
    (map 
      (fn [_] (get-random-char))
      (range pwlength))))

(defn join-charlist [charlist]
  (.join "" charlist))

(defn generate-pw [pwlength]
  (-> (make-charlist pwlength) (join-charlist)))

(defn generate-hexhash [pw]
  (-> (.encode pw) (hashlib.sha1) (.hexdigest)))

(defn split-hexhash [whole-hash first-n]
  [(cut whole-hash 0 first-n) (cut whole-hash first-n)])

(defn generate-splitted-hexhash [pw first-n]
  (-> (generate-hexhash pw) (split-hexhash first-n)))

(defn get-pwnd-response [short-hexhash api]
  (->> (+ api short-hexhash) (.urlopen urllib.request)))

(defn generate-raw-hashlist [hash-response]
  (-> (.read hash-response) (.decode) (.splitlines)))

(defn split-and-lower-hashlist-element [element]
  (-> (.split element ":") (get 0) (.lower)))

(defn generate-hashlist [hash-response]
  (->> (generate-raw-hashlist hash-response) 
       (map split-and-lower-hashlist-element)
       (list)))

(defn get-pwnd-hashlist [short-hexhash api]
  (-> (get-pwnd-response short-hexhash api) (generate-hashlist)))

(defn check-pwnd [pw api]
  (setv splitted-hexhash (generate-splitted-hexhash pw 5))
  (in 
    (get splitted-hexhash 1) 
    (get-pwnd-hashlist (get splitted-hexhash 0) api)))

(defn generate-checked-pw [pwlength api]
  (setv password (generate-pw pwlength))
  (if
    (check-pwnd password api) (generate-checked-pw pwlength api) 
    password))

(setv 
  pwnd-api "https://api.pwnedpasswords.com/range/"
  def-length 12
  min-length 10)

(print 
  (generate-checked-pw 
    (if
      (= (len sys.argv) 1) def-length
      (< (int (get sys.argv 1)) def-length) min-length 
      (int (get sys.argv 1)))
    pwnd-api))